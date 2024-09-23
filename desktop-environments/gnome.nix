{ config, pkgs, ... }:

{
  programs.dconf.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome-extension-manager
    gnomeExtensions.app-hider
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-panel
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.phi-pi-hole-indicator
    gnomeExtensions.spotify-tray
    gnomeExtensions.user-themes
  ];

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome.gnome-initial-setup
    gnome.yelp
    gnome.gnome-shell-extensions
    gnome.epiphany
    gnome-console
  ];
}
