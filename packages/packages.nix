{ config, pkgs, ... }:

{
  imports = [
    ./flatpaks.nix
    ./applications.nix
    ./system-packages.nix
    ./development.nix
    ./dependencies.nix
  ];
}
