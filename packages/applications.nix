{
  config,
  pkgs,
  system,
  inputs,
  ...
}: let
  unstable = import inputs.nixpkgs-unstable {
    config = {allowUnfree = true;};
    inherit system;
  };
  pkgs = import inputs.nixpkgs-stable {
    config = {allowUnfree = true;};
    inherit system;
  };
in {
  environment.systemPackages = with pkgs; [
    wireshark
    # gnome-terminal
    ghostty
    geary
    intune-portal
    prismlauncher
    easyeffects
    rnote
    setzer
    gimp-with-plugins
    timeshift
    gnome-boxes
    loupe
    # rpi-imager # broken
    mediawriter
    postman
    vlc
    showtime
    google-chrome
    # discord
    webcord-vencord
    spotify
    # inputs.claude.packages.${system}.claude-desktop-with-fhs
    arduino-ide
    qtcreator
    jetbrains.clion
    jetbrains.rider
    jetbrains.rust-rover
    jetbrains.idea-community
    jetbrains.pycharm-community
    kicad
  ];

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };
}
