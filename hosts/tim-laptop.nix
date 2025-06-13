{
  disks,
  config,
  pkgs,
  ...
}: {
  # Import the common configuration shared across all machines
  imports = [
    (import ../common/disko.nix {inherit disks;})
    ./desktop-only-imports.nix
    ./tim-laptop-hardware-configuration.nix
  ];

  hardware = {
    i2c = {
      enable = true;
    };
    bluetooth.settings = {
      General = {
        # The string that remote devices will see
        Name = "Tim-Laptop";
        DisablePlugins = "hostname";
      };
    };
  };

  # Machine specific configurations

  networking.hostName = "tim-laptop";
}
