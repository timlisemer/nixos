{ config, pkgs, ... }:

{

  # Import the common configuration shared across all machines
  imports = [
    ../common/common.nix
    ./tim-laptop-hardware-configuration.nix
  ];

  # Machine specific configurations

  networking.hostName = "tim-laptop";  
}
