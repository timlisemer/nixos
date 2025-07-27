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
  unstablePkgs = import inputs.nixpkgs-unstable {
    config = {allowUnfree = true;};
    inherit system;
  };
  vscodeExtensions = unstablePkgs.vscode-extensions;
in {
  environment.systemPackages = with unstablePkgs;
    lib.mkAfter [
      (vscode-with-extensions.override {
        vscodeExtensions = with vscodeExtensions;
          [
          ]
          ++ unstablePkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "claude-code";
              publisher = "anthropic";
              version = "1.0.61";
              sha256 = "17gchnyn64adhzf7ry99k8fx9wj0knkb96r7njqn6vzaxwy8kkwa";
            }
          ]
          ++ (with vscodeExtensions; [
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
          ]);
      })
      (pkgs.writeShellScriptBin "sshcode" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        WHITE='\033[1;37m'
        BLUE='\033[1;34m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        echo_info() { echo -e "''${WHITE}''${BOLD}$1''${NC}"; }
        echo_cmd() { echo -e "''${BLUE}''${BOLD}$1''${NC}"; }

        if [[ -n "''${SSH_CLIENT:-}" || -n "''${SSH_TTY:-}" ]]; then
          remote_host="''${USER}@$(hostname)"
          args=()
          if [[ $# -eq 0 ]]; then
            args=(".")
          else
            unique_dirs=()
            files=()
            for p in "$@"; do
              abs="$(realpath "$p")"
              if [[ -d "$abs" ]]; then
                args+=("$abs")
              else
                dir="$(dirname "$abs")"
                if [[ ! " ''${unique_dirs[*]} " =~ " $dir " ]]; then
                  unique_dirs+=("$dir")
                  args+=("$dir")
                fi
                files+=("$abs")
              fi
            done
            args+=("''${files[@]}")
          fi
          echo_info "To open in host VS Code:"
          echo_cmd "code --remote ssh-remote+''${remote_host} ''${args[*]}"
        else
          command code "$@"
        fi
      '')
    ];

  environment.shellAliases = {
    code = "sshcode";
  };
}
