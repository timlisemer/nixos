{
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  users,
  ...
}: {
  imports = [
    ../common/common.nix
    ../common/after_installer.nix
    ../common/desktop-only.nix
    (import ../common/home-manager.nix {
      inherit config pkgs inputs home-manager lib users;
      isDesktop = true;
      isWsl = false;
      isServer = false;
      isHomeAssistant = false;
    })
    ../packages/packages.nix
    ../desktop-environments/desktop-environments.nix
    inputs.sops-nix.nixosModules.sops
    ../secrets/sops.nix
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  environment.systemPackages = with pkgs; [
    hyprpicker
  ];

  environment.variables.DESKTOP = "1";
}
