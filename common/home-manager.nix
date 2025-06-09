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
  ...
}: let
in {
  # Import the Home Manager NixOS module
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # NixOS system-wide home-manager configuration
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
    (import ./common-home-manager.nix {
      inherit config pkgs inputs home-manager lib isDesktop isWsl isServer isHomeAssistant;
    })
  ];

  # Home Manager configuration for the user 'tim'
  home-manager.users.tim = {
    # Git configuration
    programs.git = {
      enable = true;
      userName = "timlisemer";
      userEmail = "timlisemer@gmail.com";

      # Set the default branch name using the attribute set format
      extraConfig = {
        init.defaultBranch = "main";
        safe.directory = ["/etc/nixos" "/tmp/NixOs"];
        pull.rebase = "true";
        push.autoSetupRemote = true;
        core.autocrlf = "input";
        core.eol = "lf";
      };
    };

    # Files and folders to be symlinked into home
    home.file = {
      ".config/starship.toml" = {
        source = builtins.toPath ../files/starship.toml;
        force = true;
      };
      "Pictures/Wallpapers" = {
        source = builtins.toPath ../files/Wallpapers;
        force = true;
      };
    };
  };

  home-manager.users.root = {
    # Files and folders to be symlinked into home
    home.file = {
      ".config/starship.toml" = {
        source = builtins.toPath ../files/starship-root.toml;
        force = true;
      };
    };
  };
}
