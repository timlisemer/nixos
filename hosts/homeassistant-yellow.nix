{
  modulesPath,
  config,
  pkgs,
  inputs,
  home-manager,
  nixos-raspberrypi,
  lib,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = with nixos-raspberrypi.nixosModules; [
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
      isHomeAssistant = true;
    })

    # Required: Add necessary overlays with kernel, firmware, vendor packages
    nixos-raspberrypi.lib.inject-overlays

    # Binary cache with prebuilt packages for the currently locked `nixpkgs`,
    # see `devshells/nix-build-to-cachix.nix` for a list
    trusted-nix-caches

    # Optional: All RPi and RPi-optimised packages to be available in `pkgs.rpi`
    nixpkgs-rpi

    # Optonal: add overlays with optimised packages into the global scope
    # provides: ffmpeg_{4,6,7}, kodi, libcamera, vlc, etc.
    # This overlay may cause lots of rebuilds (however many
    #  packages should be available from the binary cache)
    nixos-raspberrypi.lib.inject-overlays-global
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
        Name = "homeassistant-yellow";
        DisablePlugins = "hostname";
      };
    };
  };

  # May break stuff on arch64, but is needed for some packages
  nixpkgs.config.allowUnsupportedSystem = true;

  boot.kernelPackages = pkgs.linuxPackages_rpi5;

  # Bootloader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.timeout = lib.mkForce 1;
  boot.loader.grub = lib.mkDefault {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = false;
    devices = ["/dev/nvme0n1"]; #  Nvme Slot
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
      linuxPackages_rpi5 = stripZfs super.linuxPackages_rpi5;
    })
  ];

  hardware.graphics.extraPackages = lib.mkForce [pkgs.mesa];

  # Machine specific configurations

  networking.hostName = "homeassistant-yellow";
}
