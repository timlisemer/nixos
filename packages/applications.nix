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
    arduino-ide
    arduino-cli
  ];

  programs.steam.enable = true;
}
