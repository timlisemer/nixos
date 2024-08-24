{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    git
    curl
    wget
    nautilus-open-any-terminal
    tree
    syncthing
  ];
}
