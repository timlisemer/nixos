{ config, pkgs, inputs, home-manager, ... }:
{
  # Import the Home Manager NixOS module
  imports = [
    inputs.home-manager.nixosModules.home-manager
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

    # Firefox Theme
    # Add Firefox GNOME theme directory
    home.file.".mozilla/firefox/default/chrome/firefox-gnome-theme".source = inputs.firefox-gnome-theme;

    programs.firefox = {
      enable = true;
      profiles = {
        default = {
          id = 0;
          name = "default";
          isDefault = true;
          settings = {
            "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
            "signon.rememberSignons" = false;

            # For Firefox GNOME theme:
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.tabs.drawInTitlebar" = true;
            "svg.context-properties.content.enabled" = true;
            "widget.gtk.rounded-bottom-corners.enabled" = true;
          };
          userChrome = ''
            @import "firefox-gnome-theme/userChrome.css";
            @import "firefox-gnome-theme/theme/colors/dark.css"; 
          '';
        };
      };
    };

    imports = [ ./dconf.nix ];

    # GTK theme configuration
    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
    };

    # You can add more Home Manager configurations here, e.g.,
    # home.packages = [ pkgs.foo ];

  };
}
