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
    ../common/after_installer.nix
    ../packages/system-packages.nix
    ../packages/dependencies.nix
    (import ../common/home-manager.nix {
      inherit config pkgs inputs home-manager lib;
      isDesktop = false;
      isWsl = true;
      isServer = false;
      isHomeAssistant = false;
    })
  ];

  # Machine specific configurations
  wsl.enable = true;
  wsl.defaultUser = "tim";
  wsl.docker-desktop.enable = true;
  environment.variables.WSL = "1";
  wsl.wslConf.network.generateHosts = false;
  wsl.wslConf.interop = {
    enabled = true;
    appendWindowsPath = true;   # keeps the Windows PATH additions
  };

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };

  environment.systemPackages = with pkgs; [
    wslu
  ];

  # docker context create nixos-wsl --docker "host=tcp://localhost:2375"
  # docker context use nixos-wsl
  virtualisation.docker.daemon.settings = {
    # expose for Windows; remove if you only need CLI inside WSL
    "hosts" = [
      "unix:///var/run/docker.sock"
      "tcp://0.0.0.0:2375"
    ];
  };
}
