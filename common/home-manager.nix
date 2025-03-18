{ config, pkgs, inputs, home-manager, lib, ... }:
{
  # Import the Home Manager NixOS module
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # NixOS system-wide home-manager configuration
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  # Home Manager configuration for the user 'tim'
  home-manager.users.tim = {
    # Specify the Home Manager state version
    home.stateVersion = "24.11";

    imports = [ 
      ./dconf.nix 
      ./qemu.nix
    ];

    # Sops Home Configuration
    sops.defaultSopsFile = ../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/home/tim/.ssh/id_ed25519y" ];

    # Git configuration
    programs.git = {
      enable = true;
      userName = "timlisemer";
      userEmail = "timlisemer@gmail.com";
    
      # Set the default branch name using the attribute set format
      extraConfig = {
        init.defaultBranch = "main";
        safe.directory = [ "/etc/nixos" "/tmp/NixOs" ];
        pull.rebase = "false";
        push.autoSetupRemote = true;  
        core.autocrlf = "input";
        core.eol = "lf";
      };
    };

    # Firefox Theme
    home.file.".mozilla/firefox/default/chrome/firefox-gnome-theme".source = inputs.firefox-gnome-theme;
    home.file.".mozilla/firefox/default/chrome/userChrome.css".text = ''
      @import "firefox-gnome-theme/userChrome.css";
      @import "firefox-gnome-theme/theme/colors/dark.css";
    '';

    home.activation = {
      firefoxThemeActivation = ''
        # Ensure userContent.css exists and is non-empty
        
        mkdir -p $HOME/.mozilla/firefox/default/chrome/
        [[ -s "$HOME/.mozilla/firefox/default/chrome/userContent.css" ]] || echo >> "$HOME/.mozilla/firefox/default/chrome/userContent.css"

        # Insert @import statement at the beginning of userContent.css before any @namespace
        sed -i '1s/^/@import "firefox-gnome-theme\/userContent.css";\n/' "$HOME/.mozilla/firefox/default/chrome/userContent.css"
      '';
    };

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

            # Automatically load the YubiKey PKCS#11 module
            "security.osclientcerts.autoload" = true;
          };
        };
      };
    };


    programs.atuin = {
      enable = true;
      # https://github.com/nix-community/home-manager/issues/5734
    };

    services.gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };

    home.packages = with pkgs; [
      atuin
      sops
    ];
  
    # Files and folders to be symlinked into home
    home.file = {

      ".config/ags".source = builtins.toPath ../files/ags;
      ".config/hypr".source = builtins.toPath ../files/hypr;
      ".config/starship.toml".source = builtins.toPath ../files/starship.toml;
      ".config/wireplumber".source = builtins.toPath ../files/wireplumber;
      "Pictures/Wallpapers".source = builtins.toPath ../files/Wallpapers;
      ".bash_profile".source = builtins.toPath ../files/bash_profile;
      ".bashrc".source = builtins.toPath ../files/bashrc;
      ".stignore".source = builtins.toPath ../files/stignore;
      ".vimrc".source = builtins.toPath ../files/vimrc;

      # Arduino
      ".arduinoIDE/ia.txt" = { text = '' ia! ''; executable = false; };
      ".arduinoIDE/arduino-cli.yaml".source = builtins.toPath ../files/arduino/arduino-cli.yaml;

      # EasyEffects
      ".config/easyeffects/ia.txt" = { text = '' ia! ''; executable = false; };
      ".config/easyeffects/autoload/ia.txt" = { text = '' ia! ''; executable = false; };
      ".config/easyeffects/autoload/input/ia.txt" = { text = '' ia! ''; executable = false; };
      ".config/easyeffects/input/ia.txt" = { text = '' ia! ''; executable = false; };
      ".config/easyeffects/autoload/input/alsa_input.usb-R__DE_R__DE_NT-USB__02447C32-00.mono-fallback:.json".source = builtins.toPath ../files/easyeffects/autoload/input;
      ".config/easyeffects/input/Discord.json".source = builtins.toPath ../files/easyeffects/input;

      # OpenRGB
      ".config/OpenRGB/ia.txt" = { text = '' ia! ''; executable = false; };
      ".config/OpenRGB/plugins/settings".source = ../files/OpenRGB/plugins/settings;
      ".config/OpenRGB/Off.orp".source = ../files/OpenRGB/Off.orp;
      ".config/OpenRGB/On.orp".source = ../files/OpenRGB/On.orp;
      ".config/OpenRGB/OpenRGB.json".source = ../files/OpenRGB/OpenRGB.json;
      ".config/OpenRGB/sizes.ors".source = ../files/OpenRGB/sizes.ors;

      # nvim
      ".config/nvim/ia.txt" = { text = '' ia! ''; executable = false; };
      ".config/nvim/after".source = "${inputs.tim-nvim}/after";
      ".config/nvim/lua".source = "${inputs.tim-nvim}/lua";
      ".config/nvim/init.lua".source = "${inputs.tim-nvim}/init.lua";

      # blesh
      ".local/share/blesh".source = inputs.blesh;

      # WhatsApp
      ".config/whatsapp-for-linux/ia.txt" = { text = '' ia! ''; executable = false; };
      ".config/whatsapp-for-linux/settings.conf".source = builtins.toPath ../files/whatsapp-for-linux/settings.conf;

      # Vscode
      ".config/Code/User/ia.txt" = { text = '' ia! ''; executable = false; };
      ".config/Code/User/settings.json".source = builtins.toPath ../files/vscode/settings.json;

      # Autostart
      ".config/autostart".source = ../files/autostart;
    };

    # Steam adwaita theme
    systemd.user.services.installAdwaitaTheme = {
      Unit = {
        Description = "Install Adwaita Theme for Steam";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "install-adwaita-theme" ''
          if [ ! -d $HOME/.config/steam-adwaita-theme ]; then
            ${pkgs.git}/bin/git clone https://github.com/tkashkin/Adwaita-for-Steam $HOME/.config/steam-adwaita-theme
          else
            cd $HOME/.config/steam-adwaita-theme
            ${pkgs.git}/bin/git reset --hard
            ${pkgs.git}/bin/git pull
          fi
          cd $HOME/.config/steam-adwaita-theme
          ${pkgs.python3}/bin/python3 install.py -c adwaita -e library/hide_whats_new
        ''}";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    xdg = {
      enable = true;

      
      desktopEntries = {
        terminal = {
          name = "Terminal";
          genericName = "Default Terminal";
          exec = "ghostty";
          terminal = false;
          icon = "org.gnome.Terminal";
          categories = [ "System" "Utility" "TerminalEmulator" ];
          mimeType = [ "application/x-shellscript" "x-scheme-handler/terminal" ];
        };
      };


      mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = ["evince.desktop"];
          "x-scheme-handler/http" = ["firefox.desktop"];
          "text/html" = ["firefox.desktop"];
          "application/xhtml+xml" = ["firefox.desktop"];
          "x-scheme-handler/https" = ["firefox.desktop"];
          "text/plain" = ["code.desktop"];
          "text/markdown" = ["code.desktop"];
          "x-scheme-handler/mailto" = ["geary.desktop"];
          "text/calendar" = ["gnome-calendar.desktop"];

          # Images
          "image/jpeg" = ["org.gnome.Loupe.desktop"];
          "image/png" = ["org.gnome.Loupe.desktop"];
          "image/gif" = ["org.gnome.Loupe.desktop"];
          "image/webp" = ["org.gnome.Loupe.desktop"];
          "image/tiff" = ["org.gnome.Loupe.desktop"];
          "image/x-tga" = ["org.gnome.Loupe.desktop"];
          "image/vnd-ms.dds" = ["org.gnome.Loupe.desktop"];
          "image/x-dds" = ["org.gnome.Loupe.desktop"];
          "image/bmp" = ["org.gnome.Loupe.desktop"];
          "image/vnd.microsoft.icon" = ["org.gnome.Loupe.desktop"];
          "image/vnd.radiance" = ["org.gnome.Loupe.desktop"];
          "image/x-exr" = ["org.gnome.Loupe.desktop"];
          "image/x-portable-bitmap" = ["org.gnome.Loupe.desktop"];
          "image/x-portable-graymap" = ["org.gnome.Loupe.desktop"];
          "image/x-portable-pixmap" = ["org.gnome.Loupe.desktop"];
          "image/x-portable-anymap" = ["org.gnome.Loupe.desktop"];
          "image/x-qoi" = ["org.gnome.Loupe.desktop"];
          "image/svg+xml" = ["org.gnome.Loupe.desktop"];
          "image/svg+xml-compressed" = ["org.gnome.Loupe.desktop"];
          "image/avif" = ["org.gnome.Loupe.desktop"];
          "image/heic" = ["org.gnome.Loupe.desktop"];
          "image/jxl" = ["org.gnome.Loupe.desktop"];

          # Videos
          "video/x-ogm+ogg" = ["org.gnome.Totem.desktop"];
          "video/3gp" = ["org.gnome.Totem.desktop"];
          "video/3gpp" = ["org.gnome.Totem.desktop"];
          "video/3gpp2" = ["org.gnome.Totem.desktop"];
          "video/dv" = ["org.gnome.Totem.desktop"];
          "video/divx" = ["org.gnome.Totem.desktop"];
          "video/fli" = ["org.gnome.Totem.desktop"];
          "video/flv" = ["org.gnome.Totem.desktop"];
          "video/mp2t" = ["org.gnome.Totem.desktop"];
          "video/mp4" = ["org.gnome.Totem.desktop"];
          "video/mp4v-es" = ["org.gnome.Totem.desktop"];
          "video/mpeg" = ["org.gnome.Totem.desktop"];
          "video/mpeg-system" = ["org.gnome.Totem.desktop"];
          "video/msvideo" = ["org.gnome.Totem.desktop"];
          "video/ogg" = ["org.gnome.Totem.desktop"];
          "video/quicktime" = ["org.gnome.Totem.desktop"];
          "video/vivo" = ["org.gnome.Totem.desktop"];
          "video/vnd.divx" = ["org.gnome.Totem.desktop"];
          "video/vnd.mpegurl" = ["org.gnome.Totem.desktop"];
          "video/vnd.rn-realvideo" = ["org.gnome.Totem.desktop"];
          "video/vnd.vivo" = ["org.gnome.Totem.desktop"];
          "video/webm" = ["org.gnome.Totem.desktop"];
          "video/x-anim" = ["org.gnome.Totem.desktop"];
          "video/x-avi" = ["org.gnome.Totem.desktop"];
          "video/x-flc" = ["org.gnome.Totem.desktop"];
          "video/x-fli" = ["org.gnome.Totem.desktop"];
          "video/x-flic" = ["org.gnome.Totem.desktop"];
          "video/x-flv" = ["org.gnome.Totem.desktop"];
          "video/x-m4v" = ["org.gnome.Totem.desktop"];
          "video/x-matroska" = ["org.gnome.Totem.desktop"];
          "video/x-mjpeg" = ["org.gnome.Totem.desktop"];
          "video/x-mpeg" = ["org.gnome.Totem.desktop"];
          "video/x-mpeg2" = ["org.gnome.Totem.desktop"];
          "video/x-ms-asf" = ["org.gnome.Totem.desktop"];
          "video/x-ms-asf-plugin" = ["org.gnome.Totem.desktop"];
          "video/x-ms-asx" = ["org.gnome.Totem.desktop"];
          "video/x-msvideo" = ["org.gnome.Totem.desktop"];
          "video/x-ms-wm" = ["org.gnome.Totem.desktop"];
          "video/x-ms-wmv" = ["org.gnome.Totem.desktop"];
          "video/x-ms-wmx" = ["org.gnome.Totem.desktop"];
          "video/x-ms-wvx" = ["org.gnome.Totem.desktop"];
          "video/x-nsv" = ["org.gnome.Totem.desktop"];
          "video/x-theora" = ["org.gnome.Totem.desktop"];
          "video/x-theora+ogg" = ["org.gnome.Totem.desktop"];
          "video/x-totem-stream" = ["org.gnome.Totem.desktop"];

          # Programming files (open in VSCode)
          "application/json" = ["code.desktop"];
          "application/x-yaml" = ["code.desktop"];
          "application/x-toml" = ["code.desktop"];
          "text/x-shellscript" = ["code.desktop"];
          "text/x-python" = ["code.desktop"];
          "text/x-c" = ["code.desktop"];
          "text/x-c++" = ["code.desktop"];
          "text/x-java" = ["code.desktop"];
          "text/x-rust" = ["code.desktop"];
          "text/x-go" = ["code.desktop"];
          "text/x-javascript" = ["code.desktop"];
          "text/x-typescript" = ["code.desktop"];
          "text/x-sql" = ["code.desktop"];
          "text/x-php" = ["code.desktop"];
          "text/x-markdown" = ["code.desktop"];
          "text/x-dockerfile" = ["code.desktop"];
          "application/x-dockerfile" = ["code.desktop"];
          "text/x-docker-compose" = ["code.desktop"];
          "text/x-env" = ["code.desktop"];
          "text/x-gitignore" = ["code.desktop"];
          "text/x-makefile" = ["code.desktop"];
          "text/x-cmake" = ["code.desktop"];
          "text/x-properties" = ["code.desktop"];
          "text/x-kotlin" = ["code.desktop"];
          "text/x-swift" = ["code.desktop"];
          "text/x-lua" = ["code.desktop"];
          "text/x-ruby" = ["code.desktop"];
        };
      };
    };

  };
}
