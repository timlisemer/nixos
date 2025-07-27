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

  systemd.services.flash-silabs-firmware = {
    description = "Flash Silabs chip firmware for Thread support";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      set -euo pipefail

      # Fetch the latest firmware file name from GitHub API
      api_url="https://api.github.com/repos/darkxst/silabs-firmware-builder/contents/firmware_builds/yellow"
      latest_file=$(${pkgs.curl}/bin/curl -s "$api_url" | ${pkgs.jq}/bin/jq -r '
        [ .[] | select(.type == "file" and (.name | startswith("ot-rcp-") and endswith("-yellow-460800.gbl"))) | .name ]
        | sort_by(split("-")[2] | ltrimstr("v") | split(".") | map(tonumber)) | last
      ')

      if [ -z "$latest_file" ]; then
        echo "Error: No matching firmware file found."
        exit 1
      fi

      firmware_path="/tmp/$latest_file"
      firmware_url="https://github.com/darkxst/silabs-firmware-builder/raw/main/firmware_builds/yellow/$latest_file"

      # Download the latest firmware
      ${pkgs.curl}/bin/curl -L -o "$firmware_path" "$firmware_url"

      # Probe specifically for Spinel; temporarily disable set -e to continue on failure
      set +e
      ${pkgs.python3Packages.universal-silabs-flasher}/bin/universal-silabs-flasher --device /dev/ttyAMA10 --probe-method spinel --spinel-baudrate 460800 probe
      probe_status=$?
      set -e

      if [ $probe_status -ne 0 ]; then
        echo "Probing failed; flashing firmware..."
        ${pkgs.python3Packages.universal-silabs-flasher}/bin/universal-silabs-flasher --device /dev/ttyAMA10 --bootloader-reset yellow --spinel-baudrate 460800 flash --firmware "$firmware_path"
      else
        echo "Firmware already correct; skipping flash."
      fi
    '';
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
  };
}
