{
  config,
  inputs,
  system,
  pkgs,
  ...
}: let
  unstable = import inputs.nixpkgs-unstable {
    config = {allowUnfree = true;};
    inherit system;
  };
in {
  environment.systemPackages = with pkgs; [
    adw-gtk3
    alejandra
    autossh
    awscli2
    dbus
    nautilus-open-any-terminal
    syncthing
    libva-vdpau-driver
    comfortaa
    pciutils
    bat
    cliphist
    dejavu_fonts
    docker-buildx
    dracut
    elfutils
    ethtool
    dex
    wol
    restic
    usbutils
    fastfetch
    fd
    ffmpeg
    fzf
    gamemode
    gamescope
    unzip
    # justbuild
    pulseaudio
    sockdump
    nix-prefetch
    nix-prefetch-git
    qemu
    inetutils
    nmap
    ripgrep
    openvpn
    wireguard-tools
    trash-cli
    vdpauinfo
    resources
    rclone
    xorg.xeyes
    distrobox
    dive
    i2c-tools
    # unstable.gemini-cli
    unstable.claude-code
    unstable.qwen-code
    unstable.cursor-cli
    unstable.codex
    unstable.code-cursor
    liquidctl
    mesa-demos
    jq
    libglvnd
    mesa
    nixpkgs-fmt
    xorg.libxcb
    openal
    lsof
    rpiboot
    psmisc
    screen
    spice
    # spice-gtk
    sqlite
    tcpdump
    virt-viewer
    libvirt
    virt-manager
  ];
}
