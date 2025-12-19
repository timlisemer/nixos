{pkgs, ...}: let
  # External path to your Tauri app binary
  tauriApp = "/opt/rpi5-ui/rpi5-ui";
in {
  environment.systemPackages = with pkgs; [
    cage # Wayland compositor
    wvkbd # On-screen keyboard
  ];

  # greetd for auto-start (no display manager)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.cage}/bin/cage -s -- ${tauriApp}";
        user = "kiosk";
      };
    };
  };

  # Dedicated kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "video" "input"];
  };

  # Ensure NetworkManager is enabled for WiFi control
  networking.networkmanager.enable = true;
}
