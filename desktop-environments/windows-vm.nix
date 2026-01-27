{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.windows-vm;

  # Windows 11 icon for the desktop entry
  windowsIcon = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/AdisonCavani/distro-grub-themes/master/assets/Windows-11/icon.png";
    sha256 = "sha256-wXO/kMj1M0Lp5FJz0zTXkFI2G4JXgxKqgBQqJBrE8H0=";
    name = "windows11-icon.png";
  };

  # Fallback icon if fetch fails (embedded base64 PNG)
  fallbackIcon = pkgs.runCommand "windows11-fallback-icon" {} ''
    mkdir -p $out
    # Create a simple placeholder icon
    echo "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
    AAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAHeSURB
    VFiF7ZdNTsJQFIW/V0FFI24AN+AGdOBMHDhw4sAhKzFxA25AF4ALcAG4AFegRlQU/2jBgkJKX+/t
    fZS48yZNyO17T0/Pe+2FP/7R0MoJSqlmCYRhGO5USq0FQbA5Go3wPM9aa8MwDN+EYbhBKdVkjH1T
    St2MRqPj8XhsrbVhGIYbARCG4aCU2quU+j6dTk+m0+lK07SmYRgGpRRC6baq6xrP8wjDEMdxSNOU
    wWDAeDymqiqiKKJt25haMFxrrWeMYYyhqiqqqiLLMvI8J89zkiQhjmPyPCdJEsqypK5rlFKE4Xqh
    tCYIAuI4Js9zkiQhz3OKoiCKIoqiII5j4jimLEuUUkgpUUohhMBa+7swDDeklBellH+UUsIYgzEG
    rbU0TUNd19R1TdM0ZLNZPM9Da00URVhrsdaSkJxLaa4JKSVSSrTWOI6D7/t4nofneYRhiJQSYwxF
    UZAkCUVRkGUZZVkSRRFKKZRSaK3p9/v0ej0ODw/Z3t7+FdJxHKSUSCnpdDp0u13CMGRhYYF+v8/J
    yQmbm5ssLS0hhPjpQAixKaVU0lq7nKbp8ng8VtZagiBAa02SJLiui7UWa+2TlPIuTdM7KeVqEASk
    aepJKfV3MMZIKY+UUttSyluttf/zP/0PTWPHgbHDsF0AAAAASUVORK5CYII=" | base64 -d > $out/windows11-icon.png
  '';
in
  lib.mkIf cfg.enable {
    # Install Windows icon
    environment.systemPackages = [
      (pkgs.runCommand "windows-vm-icon" {} ''
        mkdir -p $out/share/icons/hicolor/48x48/apps
        mkdir -p $out/share/icons/hicolor/64x64/apps
        mkdir -p $out/share/icons/hicolor/128x128/apps

        # Try to use the fetched icon, fallback to placeholder
        if [ -f "${windowsIcon}" ]; then
          cp "${windowsIcon}" $out/share/icons/hicolor/48x48/apps/windows-vm.png
          cp "${windowsIcon}" $out/share/icons/hicolor/64x64/apps/windows-vm.png
          cp "${windowsIcon}" $out/share/icons/hicolor/128x128/apps/windows-vm.png
        else
          cp "${fallbackIcon}/windows11-icon.png" $out/share/icons/hicolor/48x48/apps/windows-vm.png
          cp "${fallbackIcon}/windows11-icon.png" $out/share/icons/hicolor/64x64/apps/windows-vm.png
          cp "${fallbackIcon}/windows11-icon.png" $out/share/icons/hicolor/128x128/apps/windows-vm.png
        fi
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
  }
