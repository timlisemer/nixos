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
  stable = import inputs.nixpkgs-stable {
    config = {allowUnfree = true;};
    inherit system;
  };
  vscodeExtensions = stable.vscode-extensions;
  vscodeUnstableExtensions = unstable.vscode-extensions;
in {
  environment.systemPackages = with stable;
    lib.mkAfter [
      (vscode-with-extensions.override {
        vscodeExtensions = with vscodeExtensions;
          [
          ]
          ++ unstable.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "chatgpt";
              publisher = "openai";
              version = "0.4.17";
              sha256 = "sha256-A/ta6UXAeDHQImeUqBEMDWNkevaxkGhFN1fb90S+8hY=";
            }
          ]
          ++ (with vscodeExtensions; [
            ms-python.python
            ms-python.vscode-pylance
            ms-python.debugpy
            vscodeUnstableExtensions.ms-azuretools.vscode-containers
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-containers
            ms-vscode.makefile-tools
            github.copilot
            #vscodeUnstableExtensions.github.copilot-chat
            # yy0931.vscode-sqlite3-editor
            cweijan.vscode-database-client2
            waderyan.gitblame
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
            vscodeUnstableExtensions.anthropic.claude-code
            vscodeUnstableExtensions.kilocode.kilo-code
          ]);
      })
      (stable.writeShellScriptBin "sshcode" ''
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

    # Clean and recreate Cursor extensions directory
    rm -rf /home/tim/.cursor/extensions
    mkdir -p /home/tim/.cursor/extensions

        # Copy VS Code extensions from Nix store to .cursor/extensions
        # We copy instead of symlink because Cursor needs to write to these files
        for ext_dir in $(find /nix/store -maxdepth 1 -name "*vscode-extension-*" -type d 2>/dev/null); do
          if [ -d "$ext_dir" ]; then
            # Find the actual extension directory inside share/vscode/extensions/
            actual_ext_dir=$(find "$ext_dir" -path "*/share/vscode/extensions/*" -type d | head -1)
            if [ -d "$actual_ext_dir" ]; then
              # Extract the extension name from the actual extension directory
              ext_name=$(basename "$actual_ext_dir")
              target_dir="/home/tim/.cursor/extensions/$ext_name"

              # Only copy if the extension doesn't already exist
              if [ ! -d "$target_dir" ]; then
                cp -r "$actual_ext_dir" "$target_dir" 2>/dev/null || true
                # Make the copied files writable for Cursor
                chmod -R u+w "$target_dir" 2>/dev/null || true
              fi
            fi
          fi
        done

        # Create/update Cursor extensions.json
        extensions_json="/home/tim/.cursor/extensions/extensions.json"
        echo "[" > "$extensions_json"

        first=true
        # Add each extension to extensions.json
        for ext_dir in /home/tim/.cursor/extensions/*; do
          if [ -d "$ext_dir" ] && [[ "$(basename "$ext_dir")" != "extensions.json" ]]; then
            ext_name=$(basename "$ext_dir")
            # Extract publisher and name from directory name
            # Format: publisher.name (like waderyan.gitblame)
            if [[ "$ext_name" =~ ^([^.]+)\.(.+)$ ]]; then
              publisher="''${BASH_REMATCH[1]}"
              name="''${BASH_REMATCH[2]}"
              # Try to get version from package.json
              version="1.0.0"  # default version
              if [ -f "$ext_dir/package.json" ]; then
                version_line=$(grep '"version"' "$ext_dir/package.json" | head -1)
                # Extract version using basic shell string manipulation
                version="''${version_line#*\"version\": *\"}"
                version="''${version%%\"*}"
              fi

              if [ "$first" = true ]; then
                first=false
              else
                echo "," >> "$extensions_json"
              fi

              # Add extension entry to extensions.json
              cat >> "$extensions_json" << EOF
    {"identifier":{"id":"$publisher.$name"},"version":"$version","location":{"\$mid":1,"fsPath":"/home/tim/.cursor/extensions/$ext_name","external":"file:///home/tim/.cursor/extensions/$ext_name","path":"/home/tim/.cursor/extensions/$ext_name","scheme":"file"},"relativeLocation":"$ext_name","metadata":{"installedTimestamp":$(date +%s)000,"pinned":false,"source":"gallery","id":"$(date +%s)","publisherId":"$(date +%s)","publisherDisplayName":"$publisher","targetPlatform":"universal","updated":false,"private":false,"isPreReleaseVersion":false,"hasPreReleaseVersion":false}}
    EOF
            fi
          fi
        done

        echo "]" >> "$extensions_json"

        # Set proper ownership for Cursor extensions
        chown -R tim:users /home/tim/.cursor/extensions 2>/dev/null || true
  '';
}
