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
    texlivePackages.acronym
    texlivePackages.dejavu
    texlivePackages.framed
    texlivePackages.silence
    texlivePackages.tex-gyre
    texlivePackages.tex-gyre-math
    texlivePackages.tocloft
    tree-sitter
  ];
}
