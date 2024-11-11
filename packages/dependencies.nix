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
    openssl
    pipewire
    socat
    tree-sitter


    texlive.combined.scheme-full
  ];
}
