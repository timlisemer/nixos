{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    firefox
    btop
    steam
    openrgb
    wireshark
    gnome.gnome-terminal
    minecraft
    easyeffects
    rnote
    setzer
    timeshift
    gnome.gnome-boxes
  ];
}
