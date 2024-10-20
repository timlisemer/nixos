{ config, pkgs, ... }:

{

  # Import the common configuration shared across all machines
  imports = [
    ../common/common.nix
    ./tim-pc-hardware-configuration.nix
    ../common/nvidia.nix
  ];

  # Machine specific configurations

  networking.hostName = "tim-pc";  

  boot = {
    kernelParams = [ "acpi_enforce_resources=lax" ];
    kernelModules = [ "i2c-dev" "i2c-piix4" ];
  };

  hardware = {
    i2c = {
      enable = true;
    };
  };

  # services.udev.extraRules = builtins.readFile ../files/OpenRGB/60-openrgb.rules;

  environment.systemPackages = with pkgs; [ openrgb-with-all-plugins ];

  services.hardware.openrgb.enable = true;
  systemd.user.services.openrgb = {
    description = "OpenRGB";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      # ExecStart = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --startminimized --profile 'On'";
      ExecStart = "/bin/openrgb --startminimized --profile 'On'";
      Restart = "on-failure";
    };
  };
}
