{
  disks,
  modulesPath,
  config,
  pkgs,
  inputs,
  home-manager,
  nixos-raspberrypi,
  lib,
  users,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    (import ../common/disko.nix {inherit disks;})
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
}
