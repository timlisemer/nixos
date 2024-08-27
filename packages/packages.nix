{ config, pkgs, ... }:

{
  imports = [
    ./applications.nix
    ./system-packages.nix
    ./development.nix
    ./dependencies.nix
    ./flatpaks.nix
  ];
}
