{
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  disks,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    (import ../common/disko.nix {inherit disks;})
    ../common/common.nix
    ../packages/system-packages.nix
    ../packages/dependencies.nix
    (import ../common/home-manager.nix {
      inherit config pkgs inputs home-manager lib;
      isDesktop = false;
      isWsl = false;
      isServer = true;
      isHomeAssistant = false;
    })
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.timeout = lib.mkForce 1;

  # Machine specific configurations

  networking.hostName = "tim-server";

  environment.variables.SERVER = "1";

  environment.systemPackages = with pkgs; [
  ];

  # docker context create nixos-wsl --docker "host=tcp://localhost:2375"
  # docker context use nixos-wsl
  virtualisation.docker = {
    enable = true;
    rootless.enable = true;
    rootless.setSocketVariable = true;
    # daemon.settings.ipv6 = true
  };

  virtualisation.oci-containers.containers = {
    portainer = {
      image = "portainer/portainer-ce:lts";
      autoStart = true;
      ports = ["9000:9000"]; # Expose Portainer UI on host port 9000
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock" # Allow Portainer to manage Docker
        "/var/lib/portainer:/data" # Persistent Portainer data
      ];
      cmd = ["--host" "unix:///var/run/docker.sock"];
      # Optional: if you want to limit privileges further, add extra options:
      # extraOptions = [ "--restart=always" ];
    };
  };
}
