# Kiosk configuration for Tauri app on SPI display
#
# Deployment: The Tauri app must be manually deployed to /opt/rpi5-ui/rpi5-ui
# (cross-compile for aarch64-linux and copy to the Pi)
#
# Debugging:
#   journalctl -t kiosk -n 50 --no-pager        # View kiosk script logs
#   systemctl status greetd -n 50 --no-pager    # Check greetd service
#   systemctl status seatd -n 50 --no-pager     # Check seat daemon
{pkgs, ...}: let
  tauriApp = "/opt/rpi5-ui/rpi5-ui";

  kioskScript = pkgs.writeShellScript "kiosk-start" ''
    echo "[kiosk] Starting kiosk session..."
    echo "[kiosk] User: $(whoami), UID: $(id -u)"

    # Required for Wayland compositor
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    echo "[kiosk] Setting XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
    echo "[kiosk] Created runtime directory"

    # Display configuration - dynamically find ili9486 SPI display
    # Note: SPI displays don't support GPU acceleration (EGL/GLES2)
    # Must use software rendering (pixman) - GPU only works with HDMI/DSI
    export WLR_RENDERER=pixman
    export WLR_NO_HARDWARE_CURSORS=1

    # GTK/Wayland configuration for Tauri apps
    export GDK_BACKEND=wayland
    export XCURSOR_THEME=Adwaita
    export XCURSOR_SIZE=24
    export GTK_THEME=Adwaita

    # Disable client-side decorations (no title bar, window controls)
    export GTK_CSD=0

    # GTK needs XDG_DATA_DIRS to find schemas, icons, themes
    export XDG_DATA_DIRS="/run/current-system/sw/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    export GSETTINGS_SCHEMA_DIR="/run/current-system/sw/share/glib-2.0/schemas"
    echo "[kiosk] XDG_DATA_DIRS=$XDG_DATA_DIRS"
    echo "[kiosk] GSETTINGS_SCHEMA_DIR=$GSETTINGS_SCHEMA_DIR"

    echo "[kiosk] Searching for ili9486 DRM device..."
    for driver_path in /sys/class/drm/card*/device/driver; do
      driver_name=$(basename "$(readlink -f "$driver_path")" 2>/dev/null)
      cardnum=$(echo "$driver_path" | grep -o 'card[0-9]*')
      echo "[kiosk] Checking $cardnum: driver=$driver_name"
      if [ "$driver_name" = "ili9486" ]; then
        export WLR_DRM_DEVICES="/dev/dri/$cardnum"
        echo "[kiosk] Found ili9486 display: $WLR_DRM_DEVICES"
        break
      fi
    done

    if [ -z "$WLR_DRM_DEVICES" ]; then
      echo "[kiosk] ERROR: ili9486 DRM device not found!"
      echo "[kiosk] No matching display driver. Check dtoverlay=piscreen,drm=1"
      exit 1
    fi

    echo "[kiosk] Display config: DRM=$WLR_DRM_DEVICES, RENDERER=$WLR_RENDERER"

    # Verify app exists
    if [ ! -x "${tauriApp}" ]; then
      echo "[kiosk] ERROR: App ${tauriApp} not found or not executable!"
      exit 1
    fi
    echo "[kiosk] App verified: ${tauriApp}"

    # Start cage with dbus session (needed for Tauri/GTK apps)
    echo "[kiosk] Launching cage..."

    # Use Firefox instead of Tauri app for testing
    # exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.cage}/bin/cage -d -s -- ${pkgs.firefox}/bin/firefox
    exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.cage}/bin/cage -d -s -- ${tauriApp}
  '';
in {
  # Enable dconf (GSettings backend) - required for GTK initialization
  programs.dconf.enable = true;

  # dconf profile for GTK apps - prevents "failed to commit changes" warnings
  environment.etc."dconf/profile/user".text = ''
    user-db:user
    system-db:local
  '';

  environment.systemPackages = with pkgs; [
    cage
    wvkbd
    adwaita-icon-theme
    gtk3
    gsettings-desktop-schemas
    glib
    shared-mime-info
    hicolor-icon-theme

    # WebKitGTK (used by Tauri) probes for GL even with software rendering
    libGL

    # GPU debugging tools
    mesa-demos
    libva-utils
  ];

  # Seat management daemon - required for cage/wlroots DRM access
  services.seatd.enable = true;

  services.greetd = {
    enable = true;
    # restart = false; # Don't restart on failure for auto-login
    settings = {
      default_session = {
        # Pipe all output to journalctl via systemd-cat
        command = "${pkgs.systemd}/bin/systemd-cat -t kiosk ${kioskScript}";
        user = "kiosk";
      };
    };
  };

  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "video" "input" "render" "seat"];
  };

  networking.networkmanager.enable = true;
}
