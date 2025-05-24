{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../common/common.nix
    ../common/desktop-only.nix
    ../common/home-manager.nix
    ../packages/packages.nix
    ../desktop-environments/desktop-environments.nix
    inputs.sops-nix.nixosModules.sops
    ../secrets/sops.nix
    # ./wireguard.nix
  ];

  environment.variables.WSL = "0";
}