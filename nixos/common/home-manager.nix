{ config, pkgs, home-manager, inputs, lib, ... }:

{
  # Import the Home Manager NixOS module
  imports = [
    home-manager.nixosModules.home-manager
  ];

  # Home Manager configuration for the user 'tim'
  home-manager.users.tim = {
    # Specify the Home Manager state version
    home.stateVersion = "24.05"; # Update to "24.11" if needed

    # Git configuration
    programs.git = {
      enable = true;
      userName = "timlisemer";
      userEmail = "timlisemer@gmail.com";

      # Set the default branch name using the attribute set format
      extraConfig = {
        init.defaultBranch = "main";
      };
    };

    imports = [ ./dconf.nix ];

    # You can add more Home Manager configurations here, e.g.,
    # home.packages = [ pkgs.foo ];

  };
}
