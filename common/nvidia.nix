{ config, lib, pkgs, inputs, ... }:
let
  # Import the unstable channel using the latest kernel packages
  unstable = import inputs.nixpkgs-unstable {
    config = { allowUnfree = true; };
    inherit (pkgs) system;
  };
in
{
  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
      nvidia-vaapi-driver
    ];
  };

  # Kernel Version
  boot.kernelPackages = unstable.linuxPackages_latest;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
  ];

  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;

    # Nvidia power management
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    open = false;
    nvidiaSettings = false;

    # Use the unstable Nvidia driver
    package = unstable.linuxPackages_latest.nvidiaPackages.stable;
  };
}
