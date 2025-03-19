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
    yubikey-manager
    pam_u2f
    opensc
    libfido2
    yubikey-personalization
    pam_u2f
    chromium
    pcsclite
    # pcsc-tools
    nss
    yubico-piv-tool
    nssTools
  ];
}
