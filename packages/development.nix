{ config, pkgs, inputs, ... }:

let
  vscodeExtensions = pkgs.vscode-extensions;
in
{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscodeExtensions = with vscodeExtensions; [
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        github.copilot
        github.copilot-chat
        piousdeer.adwaita-theme
        bbenoist.nix
        rust-lang.rust-analyzer
        njpwerner.autodocstring	
        svelte.svelte-vscode
      ];
    })

    arduino-ide
    qtcreator
    libsForQt5.qt5.qtbase
    kdePackages.qtbase
    # jetbrains.clion   # Test if this works again in the future
    # jetbrains.rider   # Test if this works again in the future
    jetbrains.rust-rover
    jetbrains.idea-community
    jetbrains.pycharm-community
    conda
    cmake
    composefs
    dbus
    libgcc
    jdk
    python3
    python3Packages.pip
    phpPackages.composer
    go
    gtk3
    gtk4
    julia
    libadwaita
    libinput
    lld
    libllvm
    luarocks
    lua
    meson
    nodejs
    linux-pam
    openssl
    perl
    php
    pixman
    podman
    podman-compose
    protobuf
    pkg-config
    ruby
    typescript   
    gnumake
    neovim
    gcc
    clang
    zig
    fzf
    black
    python3Packages.black
    pylint
    python3Packages.pylint
    isort
    python3Packages.isort
    stylua
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.vscode-langservers-extracted
    nodePackages.svelte-language-server
    tailwindcss-language-server
    lua-language-server
    nodePackages.graphql-language-service-cli
    emmet-ls 
    vimPlugins.nvim-treesitter-parsers.prisma
    tree-sitter-grammars.tree-sitter-prisma
    vimPlugins.vim-prisma
    vimPlugins.nvim-treesitter-parsers.regex
    vimPlugins.nvim-treesitter-parsers.bash
    vimPlugins.nvim-treesitter-parsers.markdown
    vimPlugins.nvim-treesitter-parsers.markdown_inline
    vimPlugins.mini-nvim
    pyright 
    rust-analyzer 
    prettierd
    eslint_d
  ];


}
