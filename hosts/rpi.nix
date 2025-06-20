{
  modulesPath,
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
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
      inherit config pkgs inputs home-manager lib;
      isDesktop = false;
      isWsl = false;
      isServer = false;
      isHomeAssistant = false;
    })
  ];

  # Fix shebangs in scripts # Try to bring this back to common/common.nix however currently it breaks a lot of things for example npm
  services.envfs.enable = true;

  hardware = {
    i2c = {
      enable = true;
    };
    bluetooth.settings = {
      General = {
        # The string that remote devices will see
        Name = "Tim-Raspberry-Pi";
        DisablePlugins = "hostname";
      };
    };
  };

  # May break stuff on arch64, but is needed for some packages
  nixpkgs.config.allowUnsupportedSystem = true;

  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  # Bootloader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.timeout = lib.mkForce 1;
  boot.loader.grub = lib.mkDefault {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = false;
    devices = ["/dev/mmcblk0"]; # MicroSD card
  };

  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // {allowMissing = true;});
    })
    (self: super: let
      stub = super.runCommandNoCC "empty" {} "mkdir -p $out";

      stripZfs = pkgsSet:
        pkgsSet
        // builtins.listToAttrs
        (map (n: {
            name = n;
            value = stub;
          })
          (builtins.filter (n: lib.hasPrefix "zfs" n)
            (builtins.attrNames pkgsSet)));
    in {
      intel-media-driver = stub;
      zfs =
        super.zfs
        // {
          package = stub;
          userspace = stub;
          kernel = stub;
        };
      zfs-kernel = stub;
      linuxPackages_rpi4 = stripZfs super.linuxPackages_rpi4;
    })
  ];

  hardware.graphics.extraPackages = lib.mkForce [pkgs.mesa];

  # Machine specific configurations

  networking.hostName = "tim-raspberry-pi";

  environment.systemPackages = with pkgs; [
  ];

  virtualisation.docker.storageDriver = "btrfs";

  virtualisation.oci-containers.containers = {
    # --------------------------------------------------------------------------
    # yakweide-discord-bot
    # --------------------------------------------------------------------------
    yakweide-discord-bot = {
      image = "ghcr.io/yakweide/yakweide-discord-bot:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];

      environmentFiles = [
        "/run/secrets/yakweideENV"
      ];
    };

    # --------------------------------------------------------------------------
    # vaultwarden
    # --------------------------------------------------------------------------
    vaultwarden = {
      image = "vaultwarden/server:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];

      ports = [
        "4743:4743" # hostPort:containerPort
      ];

      volumes = [
        "/mnt/docker-data/volumes/vaultwarden:/data:rw"
      ];

      environmentFiles = [
        "/run/secrets/vaultwardenEnv"
      ];

      environment = {
        SIGNUPS_ALLOWED = "false";
        INVITATIONS_ALLOWED = "true";

        ROCKET_PROFILE = "release";
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = "4743";

        DEBIAN_FRONTEND = "noninteractive";
      };
    };

    # -------------------------------------------------------------------------
    # syncthing
    # -------------------------------------------------------------------------
    syncthing = {
      image = "syncthing/syncthing:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];

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
    # traefik  (uses a secret file for the Cloudflare token)
    # -------------------------------------------------------------------------
    traefik = {
      image = "traefik:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];

      ports = [
        "443:443"
        "80:80"
        "8085:8080" # Traefik dashboard
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
    # portainer_agent
    # -------------------------------------------------------------------------
    portainer_agent = {
      image = "portainer/agent:latest";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];

      ports = ["9001:9001"];

      volumes = [
        "/mnt/docker-data/volumes/portainer:/var/lib/docker/volumes:rw"
        "/var/run/docker.sock:/var/run/docker.sock:rw"
      ];
      # No environment values needed for the agent
    };

    immich-server = {
      image = "ghcr.io/immich-app/immich-server:release";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];

      ports = [
        "2283:2283"
      ];

      volumes = [
        "/mnt/docker-data/volumes/immich/upload_location:/usr/src/app/upload:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];

      environmentFiles = [
        "/run/secrets/immichENV"
      ];

      environment = {
        "DB_HOSTNAME" = "immich_postgres";
      };
    };

    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:release";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];

      volumes = [
        "/mnt/docker-data/volumes/immich/model-cache:/cache:rw"
      ];

      environmentFiles = [
        "/run/secrets/immichENV"
      ];

      environment = {
      };
    };

    redis = {
      image = "docker.io/valkey/valkey:8-bookworm@sha256:ff21bc0f8194dc9c105b769aeabf9585fea6a8ed649c0781caeac5cb3c247884";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];
    };

    immich_postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0@sha256:fa4f6e0971f454cd95fec5a9aaed2ed93d8f46725cc6bc61e0698e97dba96da1";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm
      extraOptions = ["--network=docker-network"];

      volumes = [
        "/mnt/docker-data/volumes/immich/database:/var/lib/postgresql/data:rw"
      ];

      environmentFiles = [
        "/run/secrets/immichENV"
      ];

      environment = {
        "POSTGRES_INITDB_ARGS" = "--data-checksums";
      };
    };
  };
}
