{
  config,
  pkgs,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../common/common.nix
    # ../common/home-manager.nix
  ];

  # Machine specific configurations

  # networking.hostName = "tim-wsl"; # Dont know if this is needed or not

  wsl.enable = true;
  wsl.defaultUser = "tim";
}
