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
  };

  boot.kernelParams = ["console=tty0"];
  systemd.services."serial-getty@ttyAMA10".enable = false;

  networking.networkmanager.insertNameservers = [
    "127.0.0.1" # Primary: localhost - intentionally set to Pi-hole
    "1.1.1.1" # Backup: Cloudflare DNS
    "2606:4700:4700::1111" # Cloudflare IPv6
    "2001:4860:4860::8888" # Google DNS IPv6
  ];

  networking.firewall = lib.mkForce {
    enable = true;

    # TCP ports to open
    allowedTCPPorts = [
      22 # SSH
      53 # Pi-hole DNS
      80 # HTTP / Traefik
      443 # HTTPS / Traefik
      8000 # Portainer API
      8080 # Traefik dashboard
      8081 # Pi-hole web UI
      8082 # Filebrowser UI
      8123 # HomeAssistant
      9443 # Portainer UI
    ];

    # UDP ports to open
    allowedUDPPorts = [
      53 # Pi-hole DNS
    ];

    # ICMP (ping) is allowed separately
    allowPing = true;
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
        "8081:80/tcp" # Map to 8081 to avoid conflict with Traefik on port 80
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
        FTLCONF_webserver_port = "10.0.0.2:8081o,[::]:8081o";
        FTLCONF_webserver_webhome = "/";
        FTLCONF_dns_domainNeeded = "true";
        FTLCONF_dns_dnssec = "true";
        FTLCONF_dns_listeningMode = "all";
        FTLCONF_dns_revServers = "true,10.0.0.0/8,10.0.0.1,fritz.box";
        FTLCONF_dns_domain = "fritz.box";
      };
    };

    # -------------------------------------------------------------------------
    # homeassistant
    # -------------------------------------------------------------------------
    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = [
        "--network=host"
        "--device=/dev/dri:/dev/dri" # GPU access
        "--device=/dev/ttyAMA10:/dev/ttyAMA10"
        "--privileged"
      ];

      ports = [
        "8123:8123" # Home Assistant
      ];

      volumes = [
        "/mnt/docker-data/volumes/homeassistant/config:/config:rw"
        "/mnt/docker-data/volumes/homeassistant/media:/media:rw"
        "/run/dbus:/run/dbus:ro" # DBus access, needed for some integrations for example Bluetooth
      ];

      #environmentFiles = [
      #  "/run/secrets/homeassistantENV"
      #];

      environment.TZ = "Europe/Berlin";
    };

    # -------------------------------------------------------------------------
    # portainer
    # -------------------------------------------------------------------------
    portainer = {
      image = "portainer/portainer-ce:latest"; # Or use :lts for stability
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network" "--ip=172.18.0.3"];

      ports = [
        "8000:8000"
        "9443:9443"
      ];

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/mnt/docker-data/volumes/portainer_data:/data"
      ];
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
        "/mnt/docker-data/volumes/filebrowser:/srv:rw" # Files to browse
        "/mnt/docker-data/volumes/filebrowser/config:/config:rw" # Filebrowser config
        "/mnt/docker-data/volumes/filebrowser/database:/database:rw" # Filebrowser database
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
  };
}
