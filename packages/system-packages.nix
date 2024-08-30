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
    vaapiVdpau
    comfortaa
    bat
    cliphist
    dejavu_fonts
    dracut
    elfutils
    fastfetch
    fd
    ffmpeg
    fzf
    gamemode
    just
    justbuild
    sockdump
    qemu
    ripgrep
    trash-cli
    vdpauinfo
    wl-clipboard
    xorg.xeyes
    zoxide
    starship
    nerdfonts
    switcheroo-control
  ];
}
