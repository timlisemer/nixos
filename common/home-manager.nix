{
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  isDesktop,
  isWsl,
  isServer,
  isHomeAssistant,
  users,
  ...
}: let
in {
  # Import the Home Manager NixOS module
  imports = [
  ];

  # NixOS system-wide home-manager configuration
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
    (import ./common-home-manager.nix {
      inherit config pkgs inputs home-manager lib isDesktop isWsl isServer isHomeAssistant;
    })
  ];

  # Home Manager individual user configuration
  home-manager.users =
    lib.mapAttrs (
      _name: user: {
        lib,
        pkgs,
        ...
      }: (
        {
          programs.git = {
            enable = true;
            settings = {
              user.name = user.gitUsername;
              user.email = user.gitEmail;
              init.defaultBranch = "main";
              safe.directory = ["/etc/nixos" "/tmp/NixOs"];
              pull.rebase = "true";
              push.autoSetupRemote = true;
              core.autocrlf = "input";
              core.eol = "lf";
            };
          };
          home.file = {
            ".config/hypr/hyprland.conf" = {
              source = builtins.toPath ../files/hypr/hyprland.conf;
              force = true;
            };
          };
        }
        // (lib.optionalAttrs (_name == "tim") {
          home.activation.gameSaveSymlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
            # Create the SaveGames directory
            mkdir -p $HOME/Games/SaveGames

            # Anno 1800 save game symlink
            ANNO_TARGET="/home/tim/.local/share/Steam/steamapps/compatdata/916440/pfx/drive_c/users/steamuser/Documents/Anno 1800/accounts/6f5db650-dcf0-4fca-9b67-21a7c8ac7dc1"
            if [ -d "$ANNO_TARGET" ]; then
              ln -sfn "$ANNO_TARGET" "$HOME/Games/SaveGames/Anno 1800"
              echo "Created symlink for Anno 1800 saves"
            else
              echo "Anno 1800 save directory not found, skipping symlink"
            fi

            # Hearts of Iron IV save game symlink
            HOI4_TARGET="/home/tim/.local/share/Paradox Interactive/Hearts of Iron IV/save games"
            if [ -d "$HOI4_TARGET" ]; then
              ln -sfn "$HOI4_TARGET" "$HOME/Games/SaveGames/Hearts of Iron IV"
              echo "Created symlink for Hearts of Iron IV saves"
            else
              echo "Hearts of Iron IV save directory not found, skipping symlink"
            fi

            # Victoria 3 save game symlink
            Vic3_TARGET="/home/tim/.local/share/Paradox Interactive/Victoria 3/save games"
            if [ -d "$Vic3_TARGET" ]; then
              ln -sfn "$Vic3_TARGET" "$HOME/Games/SaveGames/Victoria 3"
              echo "Created symlink for Victoria 3 saves"
            else
              echo "Victoria 3 save directory not found, skipping symlink"
            fi

            # Europa Universalis V save game symlink
            EUV_TARGET="/home/tim/.local/share/Steam/steamapps/compatdata/3450310/pfx/drive_c/users/steamuser/Documents/Paradox Interactive/Europa Universalis V/save games"
            if [ -d "$EUV_TARGET" ]; then
              ln -sfn "$EUV_TARGET" "$HOME/Games/SaveGames/Europa Universalis V"
              echo "Created symlink for Europa Universalis V saves"
            else
              echo "Europa Universalis V save directory not found, skipping symlink"
            fi

            # Create the Extra directory
            mkdir -p $HOME/Games/Extra

            # Anno 1800 mods symlink
            ANNO_MODS_TARGET="/home/tim/.local/share/Steam/steamapps/compatdata/916440/pfx/drive_c/users/steamuser/Documents/Anno 1800/mods"
            if [ -d "$ANNO_MODS_TARGET" ]; then
              ln -sfn "$ANNO_MODS_TARGET" "$HOME/Games/Extra/Anno 1800 Mods"
              echo "Created symlink for Anno 1800 mods"
            else
              echo "Anno 1800 mods directory not found, skipping symlink"
            fi
          '';
        })
      )
    )
    users;
}
