{pkgs, ...}: let
  tauriApp = "/opt/rpi5-ui/rpi5-ui";

  kioskScript = pkgs.writeShellScript "kiosk-start" ''
    export WLR_DRM_DEVICES=/dev/dri/card2
    export WLR_RENDERER=pixman
    export WLR_NO_HARDWARE_CURSORS=1
    ${pkgs.cage}/bin/cage -s -- ${tauriApp}
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
