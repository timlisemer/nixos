{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    steam
    wireshark
    gnome-terminal
    blackbox-terminal
    geary
    minecraft
    prismlauncher
    easyeffects
    rnote
    setzer
    gimp-with-plugins
    timeshift
    gnome-boxes
    loupe
    rpi-imager
    mediawriter
    postman
    vlc
    discord-canary
    discord
    webcord-vencord
    whatsapp-for-linux
  ];

  programs.steam.enable = true;
}
