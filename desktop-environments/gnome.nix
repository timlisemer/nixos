{
  config,
  pkgs,
  ...
}: {
  programs.dconf.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
    gnomeExtensions.app-hider
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-panel
    # gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.phi-pi-hole-indicator
    gnomeExtensions.spotify-tray
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
}
