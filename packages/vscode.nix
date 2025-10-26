{
  config,
  pkgs,
  system,
  inputs,
  lib,
  users,
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

  # Define all extensions as a list for easy reference
  extensionList =
    (with vscodeExtensions; [
      coder.coder-remote
      ms-python.python
      ms-python.vscode-pylance
      ms-python.debugpy
      ms-vscode-remote.remote-containers
      ms-vscode.makefile-tools
      github.copilot
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
      foxundermoon.shell-format
      bradlc.vscode-tailwindcss
      tomoki1207.pdf
      kamadorueda.alejandra
    ])
    ++ (with vscodeUnstableExtensions; [
      ms-azuretools.vscode-containers
      anthropic.claude-code
      # kilocode.kilo-code
    ]);

  # Create a function to get extension store paths
  getExtensionPaths = extensions: builtins.map (ext: "${ext}/share/vscode/extensions") extensions;

  # Get all extension paths
  allExtensionPaths = getExtensionPaths extensionList;
  settingsSrc = builtins.toPath ../files/vscode/settings.json;
  keybindingsSrc = builtins.toPath ../files/vscode/keybindings.json;
in {
  environment.systemPackages = with stable;
    lib.mkAfter [
      (vscode-with-extensions.override {
        vscodeExtensions =
          unstable.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "chatgpt";
              publisher = "openai";
              version = "0.4.17";
              sha256 = "sha256-A/ta6UXAeDHQImeUqBEMDWNkevaxkGhFN1fb90S+8hY=";
            }
          ]
          ++ (with vscodeExtensions; [
            ms-vscode-remote.remote-ssh
            github.copilot
            github.copilot-chat
          ])
          ++ extensionList;
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

        # Copy VS Code extensions from Nix store to .vscode-server using known paths
        # We copy instead of symlink because VS Code needs to write to these files
        # and symlinks to the read-only Nix store cause EACCES permission errors
        ${builtins.concatStringsSep "\n" (builtins.map (extPath: ''
        if [ -d "${extPath}" ]; then
          for ext_dir in "${extPath}"/*; do
            if [ -d "$ext_dir" ]; then
              ext_name=$(basename "$ext_dir")
              target_dir="/home/tim/.vscode-server/extensions/$ext_name"

              # Always override existing extensions
              cp -r "$ext_dir" "$target_dir" 2>/dev/null || true
              # Make the copied files writable for VS Code
              chmod -R u+w "$target_dir" 2>/dev/null || true
            fi
          done
        fi
      '')
      allExtensionPaths)}

        # Set proper ownership
        chown -R tim:users /home/tim/.config/Code/CachedExtensionVSIXs 2>/dev/null || true
        chown -R tim:users /home/tim/.vscode-server 2>/dev/null || true

        # Clean and recreate Cursor extensions directory
        rm -rf /home/tim/.cursor/extensions
        mkdir -p /home/tim/.cursor/extensions

        # Copy VS Code extensions from Nix store to .cursor/extensions using known paths
        # We copy instead of symlink because Cursor needs to write to these files
        ${builtins.concatStringsSep "\n" (builtins.map (extPath: ''
        if [ -d "${extPath}" ]; then
          for ext_dir in "${extPath}"/*; do
            if [ -d "$ext_dir" ]; then
              ext_name=$(basename "$ext_dir")
              target_dir="/home/tim/.cursor/extensions/$ext_name"

              # Always override existing extensions
              cp -r "$ext_dir" "$target_dir" 2>/dev/null || true
              # Make the copied files writable for Cursor
              chmod -R u+w "$target_dir" 2>/dev/null || true
            fi
          done
        fi
      '')
      allExtensionPaths)}

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

  # Also run at boot so files are recreated on every reboot as well
  systemd.services."vscode-cursor-user-configs" = {
    description = "Recreate VS Code and Cursor settings for all configured users";
    after = ["local-fs.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {Type = "oneshot";};
    script = ''
      set -euo pipefail

      for user in ${lib.concatStringsSep " " (builtins.attrNames users)}; do
        home="$(${pkgs.getent}/bin/getent passwd "$user" | cut -d: -f6)"
        [ -n "${home:-}" ] || continue

        group="$(${pkgs.coreutils}/bin/id -gn "$user" 2>/dev/null || echo "users")"

        code_user_dir="$home/.config/Code/User"
        cursor_user_dir="$home/.config/Cursor/User"

        ${pkgs.coreutils}/bin/mkdir -p "$code_user_dir" "$cursor_user_dir"

        # Remove existing files to ensure clean recreation
        ${pkgs.coreutils}/bin/rm -f \
          "$code_user_dir/settings.json" \
          "$code_user_dir/keybindings.json" \
          "$cursor_user_dir/settings.json" \
          "$cursor_user_dir/keybindings.json"

        # Copy fresh files from the Nix store (not symlinks)
        ${pkgs.coreutils}/bin/cp ${settingsSrc} "$code_user_dir/settings.json"
        ${pkgs.coreutils}/bin/cp ${keybindingsSrc} "$code_user_dir/keybindings.json"
        ${pkgs.coreutils}/bin/cp ${settingsSrc} "$cursor_user_dir/settings.json"
        ${pkgs.coreutils}/bin/cp ${keybindingsSrc} "$cursor_user_dir/keybindings.json"

        # Make writable for the user and set ownership
        ${pkgs.coreutils}/bin/chmod 0644 \
          "$code_user_dir/settings.json" \
          "$code_user_dir/keybindings.json" \
          "$cursor_user_dir/settings.json" \
          "$cursor_user_dir/keybindings.json" 2>/dev/null || true

        ${pkgs.coreutils}/bin/chown -R "$user:$group" "$code_user_dir" "$cursor_user_dir" 2>/dev/null || true
      done
    '';
  };
}
