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

    # Display configuration
    export WLR_DRM_DEVICES=/dev/dri/card2
    export WLR_RENDERER=pixman
    export WLR_NO_HARDWARE_CURSORS=1
    echo "[kiosk] Display config: DRM=$WLR_DRM_DEVICES, RENDERER=$WLR_RENDERER"

    # Verify DRM device exists
    if [ ! -e "$WLR_DRM_DEVICES" ]; then
      echo "[kiosk] ERROR: DRM device $WLR_DRM_DEVICES not found!"
      ls -la /dev/dri/
      exit 1
    fi
    echo "[kiosk] DRM device verified"

    # Verify app exists
    if [ ! -x "${tauriApp}" ]; then
      echo "[kiosk] ERROR: App ${tauriApp} not found or not executable!"
      exit 1
    fi
    echo "[kiosk] App verified: ${tauriApp}"

    # Start cage with dbus session (needed for Tauri/GTK apps)
    echo "[kiosk] Launching cage..."
    exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.cage}/bin/cage -s -- ${tauriApp}
  '';
in {
  environment.systemPackages = with pkgs; [
    cage
    wvkbd
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${kioskScript}";
        user = "kiosk";
      };
    };
  };

  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "video" "input" "render"];
  };

  networking.networkmanager.enable = true;
}
