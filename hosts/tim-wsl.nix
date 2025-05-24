{
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../common/common.nix
    (import ../common/home-manager.nix ({ inherit config pkgs inputs home-manager lib; isWsl = true; }))
  ];

  # Machine specific configurations

  # networking.hostName = "tim-wsl"; # Dont know if this is needed or not

  wsl.enable = true;
  wsl.defaultUser = "tim";

  environment.systemPackages = with pkgs; [
    git
  ];
}
