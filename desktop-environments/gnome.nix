{
  config,
  pkgs,
  users,
  ...
}: let
  extensionSource = builtins.path {
    path = ../files/gnome-extensions + "/homeassistant-quicksettings@timlisemer";
    name = "homeassistant-quicksettings-timlisemer";
  };
in {
  programs.dconf.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
    gnomeExtensions.app-hider
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-panel
    # gnomeExtensions.desktop-icons-ng-ding
    # gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.phi-pi-hole-indicator
    gnomeExtensions.user-themes
  ];

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-initial-setup
    yelp
    gnome-shell-extensions
    epiphany
    gnome-console
    gnome-system-monitor
    totem
  ];

  systemd.tmpfiles.rules = builtins.concatLists (builtins.map (username: [
    "d /home/${username}/.local/share/gnome-shell/extensions 0755 ${username} users -"
    "L+ /home/${username}/.local/share/gnome-shell/extensions/homeassistant-quicksettings@timlisemer - - - - ${extensionSource}"
  ]) (builtins.attrNames users));
}
