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
    postman
    webcord-vencord
    whatsapp-for-linux
  ];

  programs.steam.enable = true;
}
