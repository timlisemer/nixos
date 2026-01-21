{
  config,
  pkgs,
  ...
}: let
  # Standard host Rust toolchain, extended with RISC-V target for ESP32-H2 cross-compilation
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    targets = ["riscv32imac-unknown-none-elf"];
    extensions = ["rust-src" "rustfmt" "clippy"];
  };
  # Nightly Rust toolchain (commented out)
  # rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
  #   targets = ["riscv32imac-unknown-none-elf"];
  #   extensions = ["rust-src" "rustfmt" "clippy"];
  # };
  rustAnalyzer = pkgs.rust-bin.stable.latest.rust-analyzer;
in {
  environment.systemPackages = with pkgs; [
    actionlint
    act
    coder
    haskellPackages.cabal-install
    glib-networking
    libcanberra-gtk2
    libdvdcss
    libva-vdpau-driver
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
    pcsclite
    # pcsc-tools
    nss
    yubico-piv-tool
    nssTools
    libsForQt5.qt5.qtbase
    kdePackages.qtbase
    conda
    cmake
    composefs
    dos2unix
    libgcc
    jdk
    (python3.withPackages (ps: with ps; [pip]))
    python3Packages.universal-silabs-flasher
    phpPackages.composer
    go
    gtk3
    gtk3.dev
    gtk4.dev
    gobject-introspection
    gjs
    julia
    libadwaita
    libinput
    lld
    libllvm
    luajit
    luajitPackages.luarocks
    meson
    linux-pam
    openssl
    openssl.dev
    perl
    php
    pixman
    protobuf
    ruby
    typescript
    gnumake
    neovim
    gcc
    zig
    fzf
    black
    python3Packages.black
    pylint
    python3Packages.pylint
    isort
    python3Packages.isort
    ruff
    mypy
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
    rustAnalyzer
    prettierd
    eslint_d
    pkg-config
    gobject-introspection
    # ESP32-H2 tooling
    espflash
    ldproxy
    openocd
    probe-rs-tools
    minicom
    rustToolchain
    cargo-edit
    cargo-tauri
    cargo-expand
    cargo-generate
    sqlite
    at-spi2-atk
    atkmm
    cairo.dev
    gdk-pixbuf.dev
    glib.dev
    gobject-introspection.dev
    libgee.dev
    xorg.libX11.dev
    atk.dev
    graphene.dev
    harfbuzz.dev
    libsoup_3
    pango.dev
    webkitgtk_4_1
    zlib
    # zlib.dev
  ];
}
