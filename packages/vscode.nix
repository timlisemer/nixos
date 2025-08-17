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
            {
              name = "sqlite-viewer";
              publisher = "qwtel";
              version = "0.10.6";
              sha256 = "dN8uW1VMlaDZn2RGxerlpCil/l4FNKE3ZOp2PSV4pY0=";
            }
          ]
          ++ (with vscodeExtensions; [
            ms-python.python
            ms-python.vscode-pylance
            ms-python.debugpy
            ms-azuretools.vscode-containers
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
            # unstable.google.geminicodeassist
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

  system.activationScripts.vscode-remote-extensions = ''
    # Create the VS Code cache directory for VSIX files
    mkdir -p /home/tim/.config/Code/CachedExtensionVSIXs
    
    # Create the remote extensions directory
    mkdir -p /home/tim/.vscode-server/extensions

    # Find all VSIX files in the Nix store and link them to the cache
    for vsix in $(find /nix/store -name "*.vsix" -type f 2>/dev/null | grep -E "(vscode-extension-|claude-code)" | head -50); do
      if [ -f "$vsix" ]; then
        # Generate a unique ID for each VSIX (using hash of the path)
        cache_id=$(echo "$vsix" | sha256sum | cut -c1-40)
        ln -sf "$vsix" "/home/tim/.config/Code/CachedExtensionVSIXs/$cache_id" 2>/dev/null || true
      fi
    done

    # Find VS Code extensions in Nix store and link to .vscode-server
    for ext_dir in $(find /nix/store -maxdepth 1 -name "*vscode-extension-*" -type d 2>/dev/null); do
      if [ -d "$ext_dir" ]; then
        # Extract the full extension name including publisher and version
        ext_name=$(basename "$ext_dir")
        # Use shell parameter expansion to remove hash prefix
        # This removes everything up to and including the first dash after the hash
        clean_name="''${ext_name#*-}"
        ln -sf "$ext_dir" "/home/tim/.vscode-server/extensions/$clean_name" 2>/dev/null || true
      fi
    done

    # Set proper ownership
    chown -R tim:users /home/tim/.config/Code/CachedExtensionVSIXs 2>/dev/null || true
    chown -R tim:users /home/tim/.vscode-server 2>/dev/null || true
  '';
}
