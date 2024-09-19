{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    steam
    wireshark
    gnome.gnome-terminal
    gnome.geary
    minecraft
    easyeffects
    rnote
    setzer
    timeshift
    gnome.gnome-boxes
    loupe
  ];
}
