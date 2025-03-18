{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    steam
    wireshark
    gnome-terminal
    ghostty
    geary
    intune-portal
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
    google-chrome
    # discord
    webcord-vencord
    whatsapp-for-linux
    spotify
  ];

  programs.steam.enable = true;
}
