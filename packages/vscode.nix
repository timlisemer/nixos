{
  config,
  pkgs,
  system,
  inputs,
  ...
}: let
  unstable = import inputs.nixpkgs-unstable {
    config = {allowUnfree = true;};
    inherit system;
  };
  pkgs = import inputs.nixpkgs-stable {
    config = {allowUnfree = true;};
    inherit system;
  };
  vscodeExtensions = pkgs.vscode-extensions;
in {
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscodeExtensions = with vscodeExtensions; [
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        ms-azuretools.vscode-docker
        # ms-azuretools.vscode-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        ms-vscode.makefile-tools
        github.copilot
        github.copilot-chat
        egirlcatnip.adwaita-github-theme
        dbaeumer.vscode-eslint
        bbenoist.nix
        tauri-apps.tauri-vscode
        rust-lang.rust-analyzer
        njpwerner.autodocstring
        svelte.svelte-vscode
        tamasfe.even-better-toml
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        foxundermoon.shell-format
        bradlc.vscode-tailwindcss
        kamadorueda.alejandra
        # google.geminicodeassist
      ];
    })
  ];
}
