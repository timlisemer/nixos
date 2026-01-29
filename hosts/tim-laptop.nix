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
    ../common/amdgpu.nix
    ../services/windows-vm
  ];

  # Windows VM with GPU passthrough (appears as GDM session)
  # Resources are auto-detected at runtime: RAM - 2GB, CPU threads - 2
  services.windows-vm = {
    enable = true;
    vmName = "windows-vm";
    username = "tim";
    password = "changeme"; # TODO: Move to SOPS

    # Storage: virtual qcow2 disk (laptop has single NVMe)
    storage = {
      type = "qcow2";
      path = "/var/lib/libvirt/images/windows.qcow2";
      size = "100G";
    };

    # PCI passthrough devices
    passthrough = {
      gpu = ["01:00.0"]; # AMD Radeon RX Vega M GL
      usb = ["00:14.0"]; # Intel USB 3.0 xHCI Controller
      audio = ["00:1f.3"]; # Intel CM238 HD Audio Controller
    };

    # Hardware types
    cpuType = "intel";
    gpuType = "amd";
  };

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
}
