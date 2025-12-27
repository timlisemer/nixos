{
  modulesPath,
  config,
  pkgs,
  inputs,
  home-manager,
  nixos-raspberrypi,
  lib,
  users,
  hostIps,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    ../common/after_installer.nix
    ./rpi-hardware-configuration.nix
    ../common/common.nix
    ../packages/system-packages.nix
    ../packages/dependencies.nix
    ../services/homeassistant.nix
    (import ../common/home-manager.nix {
      inherit config pkgs inputs home-manager lib users;
      isDesktop = false;
      isWsl = false;
      isServer = false;
      isHomeAssistant = true;
    })
  ];

  fileSystems = {
    "/" = {
      device = "/dev/nvme0n1p2";
      fsType = "ext4";
      options = ["noatime" "nodiratime" "discard"]; # Optional performance tweaks
    };

    "/boot/firmware" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077" "defaults"];
    };
  };

  # May break stuff on aarch64, but is needed for some packages
  nixpkgs.config.allowUnsupportedSystem = true;

  # Migrate to new bootloader (kernelboot is deprecated)
  # See: https://github.com/nvmd/nixos-raspberrypi/pull/61
  boot.loader.raspberryPi.bootloader = "kernel";

  # Disable power management - this is a 24/7 server
  powerManagement.enable = false;

  # Fix shebangs in scripts # Try to bring this back to common/common.nix however currently it breaks a lot of things for example npm
  services.envfs.enable = true;

  hardware = {
    i2c = {
      enable = true;
    };
    bluetooth.settings = {
      General = {
        # The string that remote devices will see
        Name = "homeassistant-yellow";
        DisablePlugins = "hostname";
      };
    };
    # Raspberry Pi hardware configuration for OpenThread RCP
    raspberry-pi.config = {
      all = {
        options = {
          enable_uart = {
            enable = true;
            value = true;
          };
          core_freq = {
            enable = true;
            value = 250;
          }; # Fixed frequency for stable UART
        };
      };
    };
  };

  # Ensure end0 still accepts Router Advertisements even with forwarding enabled globally
  boot.kernel.sysctl."net.ipv6.conf.end0.accept_ra" = 2;

  networking.networkmanager.insertNameservers = [
    "127.0.0.1" # Primary: localhost - intentionally set to Pi-hole
    "1.1.1.1" # Backup: Cloudflare DNS
    "2606:4700:4700::1111" # Cloudflare IPv6
    "2001:4860:4860::8888" # Google DNS IPv6
  ];

  # Disable wlan0 interface
  # Done to prevent mdns requests from being sent out over end0 but expected on wlan0, which would never work
  networking.wireless.enable = false;
  networking.networkmanager.unmanaged = ["interface-name:wlan0"];

  networking.firewall = lib.mkForce {
    enable = true;

    # TCP ports to open
    allowedTCPPorts = [
      22 # SSH
      53 # Pi-hole DNS
      80 # HTTP / Traefik
      443 # HTTPS / Traefik
      1883 # Mosquitto MQTT
      5540 # Matter device communication port
      5580 # Matter server
      8080 # Traefik dashboard
      8081 # OpenThread Border Router
      8082 # Filebrowser UI
      8083 # Pi-hole web UI
      8085 # Server Traefik dashboard
      8123 # HomeAssistant
      9001 # Mosquitto WebSocket
    ];

    # UDP ports to open
    allowedUDPPorts = [
      53 # Pi-hole DNS
      5353 # Multicast DNS (mDNS)
      19788 # Thread MLE (Mesh Link Establishment)
      45963 # TREL (Thread Radio Encapsulation Link)
      49154 # OpenThread Border Agent port
      61631 # Backbone Border Router (BBR) for the Thread Management Framework (TMF)
    ];

    # ICMP (ping) is allowed separately
    allowPing = true;

    trustedInterfaces = ["wpan0"]; # Allows unrestricted input from wpan0 to the host
    checkReversePath = false; # Disables rpfilter to prevent drops on routed traffic
    extraForwardRules = ''
      # --- FORWARDING RULES (IPv6) ---
      # Allow new IPv6 connections from LAN (end0) to Thread (wpan0)
      ip6 iifname "end0" oifname "wpan0" accept

      # Allow established/related IPv6 connections back from Thread to LAN
      ip6 iifname "wpan0" oifname "end0" ct state established,related accept

      # --- FORWARDING RULES (IPv4 - optional, for good measure) ---
      # This isn't needed for Thread, but doesn't hurt.
      iifname "end0" oifname "wpan0" accept
      iifname "wpan0" oifname "end0" accept
    '';

    extraCommands = ''
      ip6tables -I DOCKER-USER -i end0 -o wpan0 -j ACCEPT || true
      ip6tables -I DOCKER-USER -i wpan0 -o end0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT || true
    '';
  };

  systemd.services.fixDockerFirewall = {
    description = "Apply IPv6 forwarding rules to DOCKER-USER after Docker starts";
    after = ["docker.service"];
    bindsTo = ["docker.service"]; # Restart this service if Docker restarts
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = let
        script = pkgs.writeShellScript "fix-docker-fw.sh" ''
          #!${pkgs.runtimeShell}
          ${pkgs.iptables}/bin/ip6tables -I DOCKER-USER -i end0 -o wpan0 -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -I DOCKER-USER -i wpan0 -o end0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        '';
      in "${script}";
    };
  };

  systemd.services.tim-server-tunnel = {
    description = "Persistent SSH tunnel to tim-server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "simple";
      User = "root";
      WorkingDirectory = "/home/tim";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.autossh}/bin/autossh"
        "-M 0"
        "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -N -i /home/tim/.ssh/id_ed25519"
        "-o ExitOnForwardFailure=yes"
        "-o ServerAliveInterval=30"
        "-o ServerAliveCountMax=3"
        "-R 0.0.0.0:8123:localhost:8123"
        "-L 0.0.0.0:8085:tim-server:8085"
        "-L 0.0.0.0:4743:tim-server:4743"
        "tim@tim-server"
      ];
      Environment = [
        "AUTOSSH_GATETIME=0"
        "HOME=/home/tim"
      ];
      Restart = "always";
      RestartSec = "5s";
    };
  };

  virtualisation.oci-containers.containers = {
    # -------------------------------------------------------------------------
    # traefik  (uses a secret file for the Cloudflare token)
    # -------------------------------------------------------------------------
    traefik = {
      image = "traefik:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network" "--ip=172.18.0.2"];

      ports = [
        "443:443"
        "80:80"
        "8080:8080" # Traefik dashboard
      ];

      volumes = [
        "/mnt/docker-data/volumes/traefik:/etc/traefik:rw"
        "/var/run/docker.sock:/var/run/docker.sock:rw"
      ];

      environmentFiles = [
        "/run/secrets/traefikENV"
      ];

      environment = {
        # Keys with dots must be quoted to be valid Nix attribute names
        "traefik.http.routers.api.rule" = "Host(`traefik.local.yakweide.de`)";
        "traefik.http.routers.api.entryPoints" = "https";
        "traefik.http.routers.api.service" = "api@internal";
        "traefik.enable" = "true";
      };
    };

    # -------------------------------------------------------------------------
    # pihole
    # -------------------------------------------------------------------------
    pihole = let
      extraHosts =
        builtins.concatStringsSep ";"
        (lib.attrsets.mapAttrsToList
          (name: ip: "${ip} ${name}")
          hostIps);
    in {
      image = "pihole/pihole";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = [
        "--network=host" # Use host networking for Pi-hole
        "--cap-add=NET_ADMIN"
      ];

      ports = [
        "53:53/tcp"
        "53:53/udp"
        "8083:80/tcp" # Map to 8083 to avoid conflict with Traefik on port 80
        "67:67/udp" # DHCP
        "4711:4711/udp" # FTL metrics
      ];

      volumes = [
        "/mnt/docker-data/volumes/pihole/etc-pihole:/etc/pihole:rw"
        "/mnt/docker-data/volumes/pihole/etc-dnsmasq.d:/etc/dnsmasq.d:rw"
      ];

      environmentFiles = [
        "/run/secrets/piholePWD"
      ];

      environment = {
        TZ = "Europe/London";
        DNSMASQ_USER = "pihole";

        # ---- Pi-hole v6 settings ----
        FTLCONF_dns_hosts = extraHosts;
        FTLCONF_dns_upstreams =
          "8.8.8.8;8.8.4.4;1.1.1.1;1.0.0.1;"
          + "2001:4860:4860::8888;2001:4860:4860::8844;"
          + "2606:4700:4700::1111;2606:4700:4700::1001";
        FTLCONF_webserver_port = "10.0.0.2:8083o,[::]:8083o";
        FTLCONF_webserver_webhome = "/";
        FTLCONF_dns_domainNeeded = "true";
        FTLCONF_dns_dnssec = "true";
        FTLCONF_dns_listeningMode = "all";
        FTLCONF_dns_revServers = "true,10.0.0.0/8,10.0.0.1,fritz.box";
        FTLCONF_dns_domain = "fritz.box";
      };
    };

    # -------------------------------------------------------------------------
    # filebrowser
    # -------------------------------------------------------------------------
    filebrowser = {
      image = "filebrowser/filebrowser:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network" "--user=0:0" "--ip=172.18.0.4"];

      ports = ["8082:80"]; # Expose Filebrowser UI on host port 8082

      volumes = [
        "/mnt/docker-data/volumes/filebrowser/config:/config:rw" # Filebrowser config
        "/mnt/docker-data/volumes/filebrowser/database:/database:rw" # Filebrowser database
        "/mnt/docker-data/volumes/filebrowser/srv:/srv:rw"

        # Files to browse
        "/var/lib/homeassistant:/srv/homeassistant:rw"
        "/mnt/docker-data/volumes/traefik:/srv/traefik (homeassistant-yellow):rw"
        "/mnt/docker-data/volumes/pihole:/srv/pihole:rw"
        "/mnt/docker-data/volumes/syncthing:/srv/syncthing:rw"
        "/mnt/docker-data/volumes/openthread-border-router:/srv/openthread-border-router:rw"
        "/mnt/docker-data/volumes/matter-server:/srv/matter-server:rw"
      ];

      environment.TZ = "Europe/Berlin";
    };

    # -------------------------------------------------------------------------
    # syncthing
    # -------------------------------------------------------------------------
    syncthing = {
      image = "syncthing/syncthing:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network" "--ip=172.18.0.5"];

      # TCP and UDP ports – duplicates from the original command removed
      ports = [
        "21027:21027/tcp"
        "21027:21027/udp"
        "22000:22000/tcp"
        "22000:22000/udp"
        "22067:22067/tcp"
        "22067:22067/udp"
        "8384:8384" # Syncthing UI
      ];

      volumes = [
        "/mnt/docker-data/volumes/syncthing:/var/syncthing:rw"
      ];

      environment = {
        PUID = "99";
        PGID = "100";
        UMASK = "022";
        HOME = "/var/syncthing";
        STGUIADDRESS = "0.0.0.0:8384";
        STHOMEDIR = "/var/syncthing/config";
      };
    };

    # -------------------------------------------------------------------------
    # openthread-border-router
    # -------------------------------------------------------------------------
    openthread-border-router = {
      image = "openthread/border-router:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = [
        "--network=host"
        "--cap-add=NET_ADMIN"
        "--device=/dev/ttyUSB0:/dev/ttyUSB0"
        "--device=/dev/net/tun:/dev/net/tun"
      ];

      volumes = [
        "/mnt/docker-data/volumes/openthread-border-router:/data"
      ];

      ports = [
        "8081:8081"
        "19788:19788/udp" # Thread MLE (Mesh Link Establishment)
        "5353:5353/udp" # Multicast DNS (mDNS)
        "49154:49154/udp" # "docker exec -it openthread-border-router ot-ctl ba port" -> "49154"
        "45963:45963/udp" # TREL (Thread Radio Encapsulation Link)
        "61631:61631/udp" # Backbone Border Router (BBR) for the Thread Management Framework (TMF)
      ];

      environment = {
        OT_RCP_DEVICE = "spinel+hdlc+uart:///dev/ttyUSB0?uart-baudrate=460800";
        OT_INFRA_IF = "end0";
        OT_THREAD_IF = "wpan0";
        OT_LOG_LEVEL = "7";
        OTBR_REST_LISTEN_ADDR = "0.0.0.0";
        OTBR_VENDOR_NAME = "Tim Lisemer";
        OTBR_MODEL_NAME = "Home Assistant Yellow";
      };
    };

    # -------------------------------------------------------------------------
    # python-matter-server
    # -------------------------------------------------------------------------
    python-matter-server = {
      image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = [
        "--network=host"
        "--security-opt=apparmor=unconfined"
      ];

      # Expose Matter WebSocket API
      ports = [
        "5540:5540" # Matter device communication port
        "5580:5580" # Matter server
      ];

      volumes = [
        "/mnt/docker-data/volumes/matter-server:/data"
        "/run/dbus:/run/dbus:ro"
      ];

      environment = {
        TZ = "Europe/Berlin";
      };
    };

    # -------------------------------------------------------------------------
    # mosquitto
    # -------------------------------------------------------------------------
    mosquitto = {
      image = "eclipse-mosquitto:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network" "--ip=172.18.0.6"];

      ports = [
        "1883:1883" # MQTT
        "9001:9001" # WebSocket
      ];

      volumes = [
        "/mnt/docker-data/volumes/mosquitto/config:/mosquitto/config:rw"
        "/mnt/docker-data/volumes/mosquitto/data:/mosquitto/data:rw"
        "/mnt/docker-data/volumes/mosquitto/log:/mosquitto/log:rw"
      ];

      environment = {
        TZ = "Europe/Berlin";
      };
    };
  };

  # Override SSH settings to enable root login for homeassistant-yellow only
  services.openssh = {
    settings.PermitRootLogin = lib.mkForce "yes"; # Override global "no" setting for this host only
  };

  # Configure root user with authorized keys
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEae4h0Uk6x/lrmw0PZv/7GfWyLuEAVoc70AC4ykyFtX TimLisemer"
    ];
  };
}
