{ config, lib, pkgs, inputs, ... }:
let
  # Import the nixos-unstable channel with unfree packages enabled
  unstable = import inputs.nixpkgs-unstable {
    config = { allowUnfree = true; };
    system = "x86_64-linux";  # Explicit system string to avoid type mismatches
  };
in
{

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;

    # Nvidia power management
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    open = true;
    nvidiaSettings = false;

    # Explicitly use the stable Nvidia driver from unstable (which should be 560)
    package = unstable.linuxPackages.nvidiaPackages.stable;
  };
}
