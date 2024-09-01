{ config, pkgs, inputs, ... }:

let
  vscodeExtensions = pkgs.vscode-extensions;
in
{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscodeExtensions = with vscodeExtensions; [
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
        piousdeer.adwaita-theme
        bbenoist.nix
        rust-lang.rust-analyzer
      ];
    })

    qtcreator
    jetbrains.clion
    jetbrains.rust-rover
    jetbrains.rider
    jetbrains.idea-community
    jetbrains.pycharm-community
    conda
    cmake
    composefs
    dbus
    libgcc
    go
    gtk3
    gtk4
    julia
    libadwaita
    libinput
    lld
    libllvm
    luarocks
    meson
    nodejs
    linux-pam
    perl
    php
    pixman
    podman
    podman-compose
    protobuf
    ruby
    typescript   
    gnumake
    # neovim
    gcc
    clang
    zig
    fzf
    black
    pylint
    isort
    stylua
  ];


}
