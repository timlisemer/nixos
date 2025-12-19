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
        Name = "tim-pi5";
        DisablePlugins = "hostname";
      };
    };
  };

  # Disable graphics (console only)
  hardware.graphics.enable = false;
}
