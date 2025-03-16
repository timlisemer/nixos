{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    haskellPackages.cabal-install
    glib-networking
    intel-media-driver
    libcanberra-gtk2
    libdvdcss
    vaapiVdpau
    libva-utils
    pipewire
    socat
    tree-sitter
  ];
}
