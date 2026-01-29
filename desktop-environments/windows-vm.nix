{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.windows-vm;

  # Windows 11 icon from local files
  windowsIcon = ../files/icons/windows11-48.png;
in {
  imports = [../services/windows-vm];

  config = lib.mkIf cfg.enable {
    # Install Windows icon
    environment.systemPackages = [
      (pkgs.runCommand "windows-vm-icon" {} ''
        mkdir -p $out/share/icons/hicolor/48x48/apps
        mkdir -p $out/share/icons/hicolor/64x64/apps
        mkdir -p $out/share/icons/hicolor/128x128/apps

        cp ${windowsIcon} $out/share/icons/hicolor/48x48/apps/windows-vm.png
        cp ${windowsIcon} $out/share/icons/hicolor/64x64/apps/windows-vm.png
        cp ${windowsIcon} $out/share/icons/hicolor/128x128/apps/windows-vm.png
      '')
    ];

    # Update the session desktop entry to use the icon
    environment.etc."share/wayland-sessions/windows-vm.desktop".text = lib.mkForce ''
      [Desktop Entry]
      Name=Windows 11
      Comment=Launch Windows 11 VM with GPU passthrough
      Exec=${pkgs.writeShellScript "windows-vm-launch" ''
        # Log to journal
        log() {
          echo "[windows-vm-session] $1" | systemd-cat -t windows-vm -p info
        }

        log "Starting Windows VM session..."

        # Start the Windows VM
        ${pkgs.libvirt}/bin/virsh start ${cfg.vmName} 2>/dev/null || {
          log "Failed to start VM, may already be running"
        }

        log "VM started, waiting for shutdown..."

        # Keep the session alive while VM runs
        while ${pkgs.libvirt}/bin/virsh domstate ${cfg.vmName} 2>/dev/null | grep -q "running"; do
          sleep 5
        done

        log "VM shutdown detected, ending session."
      ''}
      Type=Application
      DesktopNames=Windows
      Icon=windows-vm
      X-GDM-SessionRegisters=true
    '';

    # GNOME-specific: Add application entry for virt-manager quick access
    environment.etc."xdg/autostart/windows-vm-status.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Windows VM Status
      Comment=Check Windows VM status
      Exec=${pkgs.writeShellScript "windows-vm-status" ''
        # Simple status check on login
        if ${pkgs.libvirt}/bin/virsh domstate ${cfg.vmName} 2>/dev/null | grep -q "running"; then
          ${pkgs.libnotify}/bin/notify-send "Windows VM" "Windows VM is currently running" -i windows-vm
        fi
      ''}
      Hidden=true
      NoDisplay=true
      X-GNOME-Autostart-enabled=true
      X-GNOME-Autostart-Phase=Applications
    '';
  };
}
