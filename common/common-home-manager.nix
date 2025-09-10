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
  astalPkgs = inputs.astal.packages.${pkgs.system};
  adwaitaHyprCursor = pkgs.stdenv.mkDerivation {
    pname = "adwaita-hyprcursor";
    version = "git";
    src = inputs.adwaita_hypercursor + "/Adwaita-HyprCursor";
    installPhase = ''
      mkdir -p $out/share/icons
      cp -r $src $out/share/icons/Adwaita-HyprCursor
    '';
  };
in {
  # Sops Home Configuration
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.sshKeyPaths = [".ssh/id_ed25519y"];

  imports =
    lib.optionals isDesktop [./dconf.nix]
    ++ [
      inputs.ags.homeManagerModules.default
      ../services/qemu.nix
    ];

  # Firefox Theme
  home.file.".mozilla/firefox/default/chrome/firefox-gnome-theme" = {
    source = inputs.firefox-gnome-theme;
    force = true;
  };
  home.file.".mozilla/firefox/default/chrome/userChrome.css" = {
    text = ''
      @import "firefox-gnome-theme/userChrome.css";
      @import "firefox-gnome-theme/theme/colors/dark.css";
    '';
    force = true;
  };

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [pkgs.web-eid-app];
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

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  nixpkgs.overlays = [
    # Register the package so the rest of the system sees it, too.
    (final: prev: {adwaita-hyprcursor = adwaitaHyprCursor;})
  ];

  home.pointerCursor = {
    package = adwaitaHyprCursor; # works in *this* module as well
    name = "Adwaita-HyprCursor";
    size = 24;
    hyprcursor.enable = true;
    gtk.enable = true;
  };

  home.packages = lib.optionals isDesktop [
    # Astal utilities
    astalPkgs.io
  ];

  programs.ags = lib.mkIf isDesktop {
    enable = true;

    # symlink to ~/.config/ags
    configDir = ../files/ags/new;

    # additional packages and executables to add to gjs's runtime
    extraPackages = with pkgs; [
      astalPkgs.notifd
      astalPkgs.tray
      astalPkgs.apps
      astalPkgs.battery
      astalPkgs.greet
      astalPkgs.mpris
      astalPkgs.network
      astalPkgs.notifd
      astalPkgs.powerprofiles
      astalPkgs.wireplumber
      astalPkgs.hyprland
    ];
  };

  home.file = {
    ".stignore" = {
      source = builtins.toPath ../files/stignore;
      force = true;
    };
    ".vimrc" = {
      source = builtins.toPath ../files/vimrc;
      force = true;
    };
    "Pictures/Wallpapers" = {
      source = builtins.toPath ../files/Wallpapers;
      force = true;
    };

    # Arduino
    ".arduinoIDE/arduino-cli.yaml" = {
      source = builtins.toPath ../files/arduino/arduino-cli.yaml;
      force = true;
    };

    # EasyEffects
    ".config/easyeffects/autoload/input/alsa_input.usb-R__DE_R__DE_NT-USB__02447C32-00.mono-fallback:.json" = {
      source = builtins.toPath ../files/easyeffects/autoload/input;
      force = true;
    };
    ".config/easyeffects/input/Discord.json" = {
      source = builtins.toPath ../files/easyeffects/input;
      force = true;
    };

    # OpenRGB
    ".config/OpenRGB/plugins/settings" = {
      source = ../files/OpenRGB/plugins/settings;
      force = true;
    };
    ".config/OpenRGB/Off.orp" = {
      source = ../files/OpenRGB/Off.orp;
      force = true;
    };
    ".config/OpenRGB/On.orp" = {
      source = ../files/OpenRGB/On.orp;
      force = true;
    };
    ".config/OpenRGB/OpenRGB.json" = {
      source = ../files/OpenRGB/OpenRGB.json;
      force = true;
    };
    ".config/OpenRGB/sizes.ors" = {
      source = ../files/OpenRGB/sizes.ors;
      force = true;
    };

    # nvim
    ".config/nvim/after" = {
      source = "${inputs.tim-nvim}/after";
      force = true;
    };
    ".config/nvim/lua" = {
      source = "${inputs.tim-nvim}/lua";
      force = true;
    };
    ".config/nvim/init.lua" = {
      source = "${inputs.tim-nvim}/init.lua";
      force = true;
    };

    # Vscode
    ".config/Code/User/settings.json" = {
      source = builtins.toPath ../files/vscode/settings.json;
      force = true;
    };
    ".config/Code/User/keybindings.json" = {
      source = builtins.toPath ../files/vscode/keybindings.json;
      force = true;
    };

    # Autostart
    ".config/autostart" = {
      source = ../files/autostart;
      force = true;
    };

    # Mimeapps
    ".config/mimeapps.list" = {
      source = builtins.toPath ../files/mimeapps.list;
      force = true;
    };

    # Gnome
    ".config/gnome-initial-setup-done" = {
      text = ''yes'';
      force = true;
      executable = false;
    };

    # Terminals
    ".config/ghostty/config" = {
      source = builtins.toPath ../files/ghostty/config;
      force = true;
    };
    ".local/share/icons/hicolor/16x16/apps/com.mitchellh.ghostty.png" = {
      source = builtins.toPath ../files/icons/ghostty/com.mitchellh.ghostty_16.png;
      force = true;
    };
    ".local/share/icons/hicolor/32x32/apps/com.mitchellh.ghostty.png" = {
      source = builtins.toPath ../files/icons/ghostty/com.mitchellh.ghostty_32.png;
      force = true;
    };
    ".local/share/icons/hicolor/128x128/apps/com.mitchellh.ghostty.png" = {
      source = builtins.toPath ../files/icons/ghostty/com.mitchellh.ghostty_128.png;
      force = true;
    };
    ".local/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png" = {
      source = builtins.toPath ../files/icons/ghostty/com.mitchellh.ghostty_256.png;
      force = true;
    };
    ".local/share/icons/hicolor/512x512/apps/com.mitchellh.ghostty.png" = {
      source = builtins.toPath ../files/icons/ghostty/com.mitchellh.ghostty_512.png;
      force = true;
    };
    ".local/share/icons/hicolor/1024x1024/apps/com.mitchellh.ghostty.png" = {
      source = builtins.toPath ../files/icons/ghostty/com.mitchellh.ghostty_1024.png;
      force = true;
    };
  };

  # Steam adwaita theme
  systemd.user.services.installAdwaitaTheme = {
    Unit = {
      Description = "Install Adwaita Theme for Steam";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
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
      WantedBy = ["default.target"];
    };
  };

  # Claude MCP servers setup
  # Check status: systemctl --user status claude-mcp-setup
  # View logs: journalctl --user -u claude-mcp-setup
  systemd.user.services.claude-mcp-setup = {
    Unit = {
      Description = "Setup Claude MCP servers on startup";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "claude-mcp-setup" ''
        # Add servers with user scope for global access
        claude mcp add nixos-search --scope user -- ssh tim-server "docker exec -i mcp-server-host sh -c 'exec 2>/dev/null; /app/servers/mcp-nixos/venv/bin/python3 -m mcp_nixos.server'"

        claude mcp add tailwind-svelte --scope user -- ssh tim-server "docker exec -i mcp-server-host node /app/servers/tailwind-svelte-assistant/dist/index.js"

        claude mcp add context7 --scope user -- ssh tim-server "docker exec -i mcp-server-host npx -y @upstash/context7-mcp"
      ''}";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
