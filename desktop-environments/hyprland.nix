{
  pkgs,
  inputs,
  ...
}: let
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
  ];

  services.gnome.gnome-keyring.enable = true;

  # Enable Polkit for authentication
  security.polkit.enable = true;
}
