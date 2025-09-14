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
  vscodeExtensions = unstable.vscode-extensions;
in {
  environment.systemPackages = with unstable;
    lib.mkAfter [
      (vscode-with-extensions.override {
        vscodeExtensions = with vscodeExtensions;
          [
          ]
          ++ unstable.vscode-utils.extensionsFromVscodeMarketplace [
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
            unstable.vscode-extensions.Google.gemini-cli-vscode-ide-companion
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

  # VS Code expects extensions in specific directories that NixOS doesn't provide by default.
  # This script creates symlinks from VS Code's expected locations to the Nix store,
  # allowing both local and remote VS Code sessions to find and use NixOS-managed extensions.
  system.activationScripts.vscode-remote-extensions = ''
    # Create the VS Code cache directory for VSIX files
    mkdir -p /home/tim/.config/Code/CachedExtensionVSIXs

    # Create the remote extensions directory
    mkdir -p /home/tim/.vscode-server/extensions

    # Clean up old symlinks in CachedExtensionVSIXs
    find /home/tim/.config/Code/CachedExtensionVSIXs -type l -delete 2>/dev/null || true

    # Clean up old extensions in .vscode-server/extensions
    # Remove both symlinks and directories that match our naming pattern
    find /home/tim/.vscode-server/extensions -type l -delete 2>/dev/null || true
    find /home/tim/.vscode-server/extensions -maxdepth 1 -name "*vscode-extension-*" -type d -exec rm -rf {} \; 2>/dev/null || true

    # Find all VSIX files in the Nix store and link them to the cache
    for vsix in $(find /nix/store -name "*.vsix" -type f 2>/dev/null | grep -E "(vscode-extension-|claude-code)" | head -50); do
      if [ -f "$vsix" ]; then
        # Generate a unique ID for each VSIX (using hash of the path)
        cache_id=$(echo "$vsix" | sha256sum | cut -c1-40)
        ln -sf "$vsix" "/home/tim/.config/Code/CachedExtensionVSIXs/$cache_id" 2>/dev/null || true
      fi
    done

    # Copy VS Code extensions from Nix store to .vscode-server
    # We copy instead of symlink because VS Code needs to write to these files
    # and symlinks to the read-only Nix store cause EACCES permission errors
    for ext_dir in $(find /nix/store -maxdepth 1 -name "*vscode-extension-*" -type d 2>/dev/null); do
      if [ -d "$ext_dir" ]; then
        # Extract the full extension name
        ext_name=$(basename "$ext_dir")
        # Remove the hash prefix and "vscode-extension-" to get a clean name
        # Format: hash-vscode-extension-publisher-name-version
        clean_name="''${ext_name#*vscode-extension-}"
        target_dir="/home/tim/.vscode-server/extensions/$clean_name"

        # Only copy if the extension doesn't already exist
        if [ ! -d "$target_dir" ]; then
          cp -r "$ext_dir" "$target_dir" 2>/dev/null || true
          # Make the copied files writable for VS Code
          chmod -R u+w "$target_dir" 2>/dev/null || true
        fi
      fi
    done

    # Set proper ownership
    chown -R tim:users /home/tim/.config/Code/CachedExtensionVSIXs 2>/dev/null || true
    chown -R tim:users /home/tim/.vscode-server 2>/dev/null || true
  '';
}
