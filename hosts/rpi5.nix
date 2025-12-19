{
  modulesPath,
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  users,
  hostName,
  ...
}: {
  imports = [
    ../common/after_installer.nix
    ../common/common.nix
    ../packages/system-packages.nix
    ../packages/dependencies.nix
    (import ../common/home-manager.nix {
      inherit config pkgs inputs home-manager lib users;
      isDesktop = false;
      isWsl = false;
      isServer = false;
      isHomeAssistant = false;
    })
  ];

  # Filesystem configuration for MicroSD boot
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077" "defaults"];
    };
  };

  # May break stuff on aarch64, but is needed for some packages
  nixpkgs.config.allowUnsupportedSystem = true;

  # Use kernel bootloader (not deprecated kernelboot)
  boot.loader.raspberryPi.bootloader = "kernel";

  # Disable power management - this is a 24/7 server
  powerManagement.enable = false;

  # Fix shebangs in scripts
  services.envfs.enable = true;

  # DHCP networking
  networking.useDHCP = lib.mkDefault true;

  hardware = {
    i2c.enable = true;
    bluetooth.settings = {
      General = {
        Name = "rpi5";
        DisablePlugins = "hostname";
      };
    };

    # SPI display configuration for 3.5" ILI9486 TFT
    raspberry-pi.config = {
      all = {
        # Enable SPI via dtparam
        base-dt-params = {
          spi = {
            enable = true;
            value = "on";
          };
        };
        # Device tree overlays
        dt-overlays = {
          # piscreen overlay for ILI9486 3.5" displays with DRM support
          piscreen = {
            enable = true;
            params = {
              drm = {
                enable = true;
                value = true;
              };
              speed = {
                enable = true;
                value = 16000000; # 16MHz SPI speed
              };
            };
          };
          # Touch controller (XPT2046/ADS7846)
          # TODO: Touch not yet tested - cs/penirq pins may need adjustment
          ads7846 = {
            enable = true;
            params = {
              cs = {
                enable = true;
                value = 1; # CE1 for touch
              };
              penirq = {
                enable = true;
                value = 25; # GPIO25 for touch interrupt
              };
            };
          };
        };
      };
    };
  };
}
