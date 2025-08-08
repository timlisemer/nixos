{
  modulesPath,
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  disks,
  users,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    ../common/after_installer.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../common/common.nix
    ../packages/vscode.nix
    ../packages/system-packages.nix
    ../packages/dependencies.nix
    (import ../common/home-manager.nix {
      inherit config pkgs inputs home-manager lib users;
      isDesktop = false;
      isWsl = false;
      isServer = true;
      isHomeAssistant = false;
    })
  ];

  # Fix shebangs in scripts # Try to bring this back to common/common.nix however currently it breaks a lot of things for example npm
  services.envfs.enable = true;

  # Conditionally disable sops for image generation (when /etc/ssh keys don't exist)
  sops.secrets = lib.mkIf (builtins.pathExists /etc/ssh/ssh_host_rsa_key) (lib.mkDefault {});

  # Bootloader
  boot.loader.timeout = lib.mkForce 1;
  boot.loader.grub = lib.mkForce {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Machine specific configurations

  environment.variables.SERVER = "1";

  networking.networkmanager.insertNameservers = [
    "1.1.1.1" # Primary: Cloudflare DNS
    "8.8.8.8" # Backup: Google DNS
    "2606:4700:4700::1111" # Cloudflare IPv6
    "2001:4860:4860::8888" # Google DNS IPv6
  ];

  networking.firewall = lib.mkForce {
    enable = true;

    # TCP ports to open
    allowedTCPPorts = [
      22 # SSH
      80 # Traefik HTTP
      443 # HTTPS / Traefik
    ];

    # UDP ports to open
    allowedUDPPorts = [
    ];

    # ICMP (ping) is allowed separately
    allowPing = true;
  };

  environment.systemPackages = with pkgs; [
  ];

  programs.regreet.enable = true;
}
