{
  pkgs,
  inputs,
  ...
}: let
  astalPkgs = inputs.astal.packages.${pkgs.system};
in {
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hyprland related packages
  environment.systemPackages = with pkgs; [
    cliphist
    grim
    slurp
    pamixer
    playerctl
    evtest

    # Astal utilities
    astalPkgs.io
    astalPkgs.notifd
    astalPkgs.tray
    astalPkgs.apps
    astalPkgs.battery
    astalPkgs.greet
    astalPkgs.mpris
    astalPkgs.network
    astalPkgs.notifd
    astalPkgs.powerprofiles
    astalPkgs.wireplumber
    astalPkgs.hyprland
  ];

  services.gnome.gnome-keyring.enable = true;

  # Enable Polkit for authentication
  security.polkit.enable = true;
}
