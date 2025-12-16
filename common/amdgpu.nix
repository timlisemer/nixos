{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable hardware accelerated graphics
  # AMD uses Mesa's RADV for Vulkan, radeonsi for OpenGL/VA-API
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # For 32-bit apps (Wine, Steam)
  };

  # Load amdgpu kernel module in initrd for proper resolution during early boot
  hardware.amdgpu.initrd.enable = true;

  # Enable OpenCL support via ROCm runtime
  hardware.amdgpu.opencl.enable = true;

  # Enable overdrive for GPU management features (required for LACT fan curves/overclocking)
  hardware.amdgpu.overdrive.enable = true;

  # LACT daemon for GPU management (monitoring, fan curves, overclocking)
  services.lact.enable = true;
}
