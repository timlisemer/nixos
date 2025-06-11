{
  config,
  pkgs,
  inputs,
  home-manager,
  ...
}: let
in {
  imports = [
    home-manager.nixosModules.home-manager
  ];

  home-manager.sharedModules = [
    {
      home.stateVersion = "25.05";
      home.file = {
        ".bash_profile" = {
          source = builtins.toPath ../files/bash_profile;
          force = true;
        };
        ".bashrc" = {
          source = builtins.toPath ../files/bashrc;
          force = true;
        };
      };

      programs.atuin = {
        enable = true;
        # https://github.com/nix-community/home-manager/issues/5734
      };
    }
  ];

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
