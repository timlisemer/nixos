{
  config,
  pkgs,
  lib,
  cfg,
  pciToDomain,
}: let
  # GPU driver based on type
  gpuDriver =
    if cfg.gpuType == "amd"
    then "amdgpu"
    else if cfg.gpuType == "nvidia"
    then "nvidia"
    else "i915";

  # GPU audio driver (usually snd_hda_intel for all)
  gpuAudioDriver = "snd_hda_intel";

  # Build device lists with full domain format
  gpuDevices = map pciToDomain cfg.passthrough.gpu;
  usbDevices = map pciToDomain cfg.passthrough.usb;
  audioDevices = map pciToDomain cfg.passthrough.audio;
  allDevices = gpuDevices ++ usbDevices ++ audioDevices;

  # Generate unbind commands for prepare phase
  unbindScript = pkgs.writeShellScript "windows-vm-unbind" ''
    set -euo pipefail

    log() {
      echo "[windows-vm] $1" | systemd-cat -t windows-vm -p info
    }

    log "Starting device unbind for Windows VM..."

    # Stop display manager
    log "Stopping display-manager..."
    systemctl stop display-manager || true
    sleep 2

    # Unbind VT consoles
    log "Unbinding VT consoles..."
    echo 0 > /sys/class/vtconsole/vtcon0/bind 2>/dev/null || true
    echo 0 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null || true

    # Unbind EFI framebuffer
    log "Unbinding EFI framebuffer..."
    echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true

    # Unload GPU driver
    log "Unloading ${gpuDriver} driver..."
    modprobe -r ${gpuDriver} 2>/dev/null || true
    ${lib.optionalString (cfg.gpuType == "amd") ''
      modprobe -r amdgpu 2>/dev/null || true
    ''}

    # Unbind GPU devices
    ${lib.concatMapStrings (dev: ''
        log "Unbinding GPU device ${dev}..."
        if [ -e "/sys/bus/pci/devices/${dev}/driver" ]; then
          echo "${dev}" > "/sys/bus/pci/devices/${dev}/driver/unbind" 2>/dev/null || true
        fi
      '')
      gpuDevices}

    # Unbind USB controllers
    ${lib.concatMapStrings (dev: ''
        log "Unbinding USB controller ${dev}..."
        if [ -e "/sys/bus/pci/devices/${dev}/driver" ]; then
          echo "${dev}" > "/sys/bus/pci/devices/${dev}/driver/unbind" 2>/dev/null || true
        fi
      '')
      usbDevices}

    # Unbind audio devices
    ${lib.concatMapStrings (dev: ''
        log "Unbinding audio device ${dev}..."
        if [ -e "/sys/bus/pci/devices/${dev}/driver" ]; then
          echo "${dev}" > "/sys/bus/pci/devices/${dev}/driver/unbind" 2>/dev/null || true
        fi
      '')
      audioDevices}

    # Load vfio-pci
    log "Loading vfio-pci module..."
    modprobe vfio-pci

    # Bind all devices to vfio-pci
    ${lib.concatMapStrings (dev: ''
        log "Binding ${dev} to vfio-pci..."
        echo "vfio-pci" > "/sys/bus/pci/devices/${dev}/driver_override" 2>/dev/null || true
        echo "${dev}" > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || true
      '')
      allDevices}

    log "Device unbind complete."
  '';

  # Generate rebind commands for release phase
  rebindScript = pkgs.writeShellScript "windows-vm-rebind" ''
    set -euo pipefail

    log() {
      echo "[windows-vm] $1" | systemd-cat -t windows-vm -p info
    }

    log "Starting device rebind after Windows VM shutdown..."

    # Unbind all devices from vfio-pci
    ${lib.concatMapStrings (dev: ''
        log "Unbinding ${dev} from vfio-pci..."
        if [ -e "/sys/bus/pci/devices/${dev}/driver" ]; then
          echo "${dev}" > "/sys/bus/pci/devices/${dev}/driver/unbind" 2>/dev/null || true
        fi
        echo "" > "/sys/bus/pci/devices/${dev}/driver_override" 2>/dev/null || true
      '')
      allDevices}

    ${lib.optionalString (cfg.gpuType == "amd") ''
      # AMD GPU reset workaround
      log "Performing AMD GPU reset workaround..."
      ${lib.concatMapStrings (dev: ''
          echo 1 > "/sys/bus/pci/devices/${dev}/remove" 2>/dev/null || true
        '')
        gpuDevices}
      sleep 1
      echo 1 > /sys/bus/pci/rescan
      sleep 2
    ''}

    # Rebind GPU to native driver
    log "Loading ${gpuDriver} driver..."
    modprobe ${gpuDriver} || true
    sleep 1

    # Rebind GPU devices
    ${lib.concatMapStrings (dev: ''
        log "Rebinding GPU ${dev}..."
        echo "${dev}" > /sys/bus/pci/drivers/${gpuDriver}/bind 2>/dev/null || true
      '')
      (lib.take 1 gpuDevices)}

    # Rebind GPU audio (if present)
    ${lib.optionalString (lib.length gpuDevices > 1) ''
      log "Rebinding GPU audio..."
      echo "${lib.elemAt gpuDevices 1}" > /sys/bus/pci/drivers/snd_hda_intel/bind 2>/dev/null || true
    ''}

    # Rebind USB controllers
    ${lib.concatMapStrings (dev: ''
        log "Rebinding USB ${dev}..."
        echo "${dev}" > /sys/bus/pci/drivers/xhci_hcd/bind 2>/dev/null || true
      '')
      usbDevices}

    # Rebind audio devices
    ${lib.concatMapStrings (dev: ''
        log "Rebinding audio ${dev}..."
        echo "${dev}" > /sys/bus/pci/drivers/snd_hda_intel/bind 2>/dev/null || true
      '')
      audioDevices}

    # Re-bind VT consoles
    log "Rebinding VT consoles..."
    sleep 1
    echo 1 > /sys/class/vtconsole/vtcon0/bind 2>/dev/null || true
    echo 1 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null || true

    # Rebind EFI framebuffer
    log "Rebinding EFI framebuffer..."
    echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind 2>/dev/null || true

    # Restart display manager
    log "Starting display-manager..."
    sleep 2
    systemctl start display-manager || true

    log "Device rebind complete."
  '';

  # Main QEMU hook script
  qemuHook = pkgs.writeShellScript "qemu" ''
    #!/bin/bash
    GUEST_NAME="$1"
    OPERATION="$2"
    SUB_OPERATION="$3"

    if [ "$GUEST_NAME" != "${cfg.vmName}" ]; then
      exit 0
    fi

    case "$OPERATION/$SUB_OPERATION" in
      prepare/begin)
        ${unbindScript}
        ;;
      release/end)
        ${rebindScript}
        ;;
    esac
  '';
in {
  # Hook setup during libvirtd start
  hookSetup = "";

  # Activation script to install hooks
  activationScript = {
    text = ''
      # Create libvirt hooks directory
      mkdir -p /var/lib/libvirt/hooks

      # Install QEMU hook
      cp ${qemuHook} /var/lib/libvirt/hooks/qemu
      chmod +x /var/lib/libvirt/hooks/qemu

      # Ensure proper ownership
      chown -R root:root /var/lib/libvirt/hooks
    '';
    deps = [];
  };
}
