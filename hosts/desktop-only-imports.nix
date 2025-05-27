{
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  ...
}: {
  imports = [
    ../common/common.nix
    ../common/desktop-only.nix
    (import ../common/home-manager.nix {
      inherit config pkgs inputs home-manager lib;
      isWsl = false;
    })
    ../packages/packages.nix
    ../desktop-environments/desktop-environments.nix
    inputs.sops-nix.nixosModules.sops
    ../secrets/sops.nix
    # ./wireguard.nix
  ];

  environment.variables.WSL = "0";
}
