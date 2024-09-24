{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    steam
    wireshark
    gnome.gnome-terminal
    blackbox-terminal
    gnome.geary
    minecraft
    easyeffects
    rnote
    setzer
    timeshift
    gnome.gnome-boxes
    loupe
    rpi-imager
    mediawriter
  ];

  programs.steam.enable = true;
}
