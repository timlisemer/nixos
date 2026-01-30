{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.windows-vm;

  # Helper to convert PCI address (03:00.0) to domain format (0000:03:00.0)
  pciToDomain = addr: "0000:${addr}";

  # Collect all PCI devices for VFIO
  allPciDevices = cfg.passthrough.gpu ++ cfg.passthrough.usb ++ cfg.passthrough.audio;

  # Import submodules
  hooksModule = import ./hooks.nix {inherit config pkgs lib cfg pciToDomain;};
  vmXmlModule = import ./vm-xml.nix {inherit config pkgs lib cfg pciToDomain;};
  windowsIsoModule = import ./windows-iso.nix {inherit config pkgs lib cfg;};
in {
  options.services.windows-vm = {
    enable = mkEnableOption "Windows VM with GPU passthrough as GDM session";

    vmName = mkOption {
      type = types.str;
      default = "windows-vm";
      description = "Name of the libvirt VM";
    };

    username = mkOption {
      type = types.str;
      default = "user";
      description = "Windows username for unattended install";
    };

    password = mkOption {
      type = types.str;
      default = "changeme";
      description = "Windows password for unattended install (plain text for now, SOPS later)";
    };

    storage = {
      type = mkOption {
        type = types.enum ["raw" "qcow2"];
        default = "qcow2";
        description = "Storage type: 'raw' for block device passthrough, 'qcow2' for image file";
      };

      device = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Block device path for raw storage (e.g., /dev/disk/by-id/nvme-...)";
      };

      path = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path for qcow2 image file (e.g., /mnt/vm-data/<vm-name>/disk.qcow2)";
      };

      size = mkOption {
        type = types.str;
        default = "200G";
        description = "Size for qcow2 image (ignored for raw)";
      };
    };

    passthrough = {
      gpu = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["03:00.0" "03:00.1"];
        description = "PCI addresses for GPU passthrough (GPU + GPU audio)";
      };

      usb = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["7b:00.3" "7b:00.4"];
        description = "PCI addresses for USB controller passthrough";
      };

      audio = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["7b:00.6"];
        description = "PCI addresses for audio controller passthrough";
      };
    };

    cpuType = mkOption {
      type = types.enum ["amd" "intel"];
      default = "amd";
      description = "CPU type for IOMMU configuration";
    };

    gpuType = mkOption {
      type = types.enum ["amd" "nvidia" "intel"];
      default = "amd";
      description = "GPU type for driver unbind/rebind";
    };

    noHybridGraphics = mkOption {
      type = types.bool;
      description = ''
        Does this system NOT have hybrid/switchable graphics?

        This setting controls whether IOMMU kernel parameters (intel_iommu=on
        or amd_iommu=on) are added to your boot configuration.

        SET TO TRUE IF:
        - Desktop PC with a dedicated GPU
        - Workstation with discrete graphics
        - Any system where the GPU is always powered on

        SET TO FALSE IF:
        - Laptop with hybrid/switchable graphics (Intel iGPU + discrete GPU)
        - Laptop with NVIDIA Optimus or AMD Switchable Graphics
        - Any system where the discrete GPU enters power-saving sleep states

        WARNING: Setting this incorrectly can cause an UNRECOVERABLE KERNEL PANIC.
        The panic does NOT occur during nixos-rebuild - it happens on REBOOT.
        This means you may need to reinstall your system if you set this wrong.

        Technical details: On hybrid graphics laptops, the discrete GPU enters
        D3hot power-saving state when not in use. The intel_iommu kernel parameter
        prevents the GPU from waking from this sleep state, causing a kernel panic
        when the system tries to access the GPU after boot.

        This option has no default - you must explicitly choose.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.storage.type == "raw" -> cfg.storage.device != null;
        message = "services.windows-vm.storage.device must be set when using raw storage type";
      }
      {
        assertion = cfg.storage.type == "qcow2" -> cfg.storage.path != null;
        message = "services.windows-vm.storage.path must be set when using qcow2 storage type";
      }
      {
        assertion = cfg.passthrough.gpu != [];
        message = "services.windows-vm.passthrough.gpu must contain at least one PCI address";
      }
      {
        assertion = cfg ? noHybridGraphics;
        message = ''
          services.windows-vm.noHybridGraphics must be explicitly set.

          This setting controls IOMMU kernel parameters that can cause
          UNRECOVERABLE KERNEL PANICS if set incorrectly.

          The panic does NOT occur during nixos-rebuild - it happens on REBOOT.
          You may need to reinstall your system if you choose wrong.

          Set to TRUE if: System has NO hybrid graphics (GPU always powered)
          Set to FALSE if: System HAS hybrid graphics (GPU sleeps to save power)

          Examples:
            noHybridGraphics = true;   # Desktop PC, workstation
            noHybridGraphics = false;  # Laptop with Intel + NVIDIA/AMD switchable graphics

          If unsure, set to FALSE - the VM won't work but your system won't panic.
        '';
      }
    ];

    # Kernel parameters for IOMMU (only on systems without hybrid graphics)
    boot.kernelParams =
      (lib.optionals cfg.noHybridGraphics (
        if cfg.cpuType == "amd"
        then ["amd_iommu=on" "iommu=pt"]
        else ["intel_iommu=on" "iommu=pt"]
      ))
      ++ ["kvm.ignore_msrs=1" "kvm.report_ignored_msrs=0"];

    # VFIO modules in initrd
    boot.initrd.kernelModules = ["vfio_pci" "vfio" "vfio_iommu_type1"];

    # Ensure VFIO modules load early
    boot.kernelModules = ["kvm" "kvm_${cfg.cpuType}"];

    # Enable libvirt with QEMU (OVMF images are available by default)
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    # Required packages
    environment.systemPackages = with pkgs; [
      virt-manager
      looking-glass-client
      swtpm
      OVMF
      pciutils
      usbutils
      aria2
      wimlib
      cabextract
      chntpw
    ];

    # Add users to libvirt group
    users.groups.libvirt = {};

    # Libvirt hooks for GPU passthrough
    systemd.services.libvirtd-config.preStart = hooksModule.hookSetup;

    # Create qemu hook directory and scripts
    system.activationScripts.libvirt-hooks = hooksModule.activationScript;

    # VM XML definition service
    systemd.services.windows-vm-define = vmXmlModule.defineService;

    # Windows ISO download activation script (non-blocking background download)
    system.activationScripts.windows-iso-download = windowsIsoModule.activationScript;

    # Create the GDM session entry
    environment.etc."share/wayland-sessions/windows-vm.desktop".text = ''
      [Desktop Entry]
      Name=Windows 11
      Comment=Launch Windows 11 VM with GPU passthrough
      Exec=${pkgs.writeShellScript "windows-vm-launch" ''
        # Start the Windows VM
        ${pkgs.libvirt}/bin/virsh start ${cfg.vmName} 2>/dev/null || true

        # Keep the session alive while VM runs
        while ${pkgs.libvirt}/bin/virsh domstate ${cfg.vmName} 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "running"; do
          sleep 5
        done
      ''}
      Type=Application
      DesktopNames=Windows
    '';

    # Symlink to standard session locations
    environment.etc."share/xsessions/windows-vm.desktop".source =
      config.environment.etc."share/wayland-sessions/windows-vm.desktop".source;

    # Ensure session directories exist
    systemd.tmpfiles.rules = [
      "d /usr/share/wayland-sessions 0755 root root -"
      "d /usr/share/xsessions 0755 root root -"
      "L+ /usr/share/wayland-sessions/windows-vm.desktop - - - - /etc/share/wayland-sessions/windows-vm.desktop"
      "L+ /usr/share/xsessions/windows-vm.desktop - - - - /etc/share/wayland-sessions/windows-vm.desktop"
    ];
  };
}
