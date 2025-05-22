{
  config,
  pkgs,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    (import ../install.nix {disks = ["/dev/nvme0n1"];})
    ./desktop-only-imports.nix
    ./tim-laptop-hardware-configuration.nix
  ];

  # Machine specific configurations

  networking.hostName = "tim-laptop";
}
