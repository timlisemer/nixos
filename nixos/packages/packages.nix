{ config, pkgs, ... }:

{
  imports = [
    ./applications.nix
    ./system-packages.nix
    ./development.nix
  ];
}
