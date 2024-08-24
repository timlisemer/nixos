{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    openrgb
    wireshark
    gnome.gnome-terminal
    minecraft
    easyeffects
  ];
}
