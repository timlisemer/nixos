# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "ca/desrt/dconf-editor" = {
      saved-pathbar-path = "/org/gnome/shell/extensions/dash-to-panel/";
      saved-view = "/org/gnome/shell/extensions/dash-to-panel/";
      window-height = 500;
      window-is-maximized = false;
      window-width = 540;
    };

    "org/gnome/Console" = {
      last-window-size = mkTuple [ 652 480 ];
    };

    "org/gnome/GWeather4" = {
      temperature-unit = "centigrade";
    };

    "org/gnome/Geary" = {
      ask-open-attachment = true;
      compose-as-html = true;
      formatting-toolbar-visible = false;
      migrated-config = true;
      run-in-background = true;
    };

    "org/gnome/Snapshot" = {
      is-maximized = false;
    };


    "org/gnome/Totem" = {
      active-plugins = [ "vimeo" "variable-rate" "skipto" "screenshot" "screensaver" "save-file" "rotation" "recent" "movie-properties" "open-directory" "mpris" "autoload-subtitles" "apple-trailers" ];
      subtitle-encoding = "UTF-8";
    };

    "org/gnome/Weather" = {
      locations = [ (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Frankfurt" "EDDF" false [ (mkTuple [ (mkDouble "0.8735372906231619") (mkDouble "0.15009831567151233") ]) ] (mkArray "(dd)" []) ])) ])) (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Frankfurt" "EDDF" true [ (mkTuple [ (mkDouble "0.8735372906231619") (mkDouble "0.15009831567151233") ]) ] [ (mkTuple [ (mkDouble "0.874700849275589") (mkDouble "0.15155275089707676") ]) ] ])) ])) ];
      window-height = 512;
      window-maximized = false;
      window-width = 992;
    };

    "org/gnome/calendar" = {
      active-view = "month";
      window-maximized = true;
    };

    "org/gnome/clocks" = {
      world-clocks = [ [
        (mkDictionaryEntry ["location" (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Los Angeles" "KCQT" true [ (mkTuple [ (mkDouble "0.5937028397045019") (mkDouble "-2.064433611082862") ]) ] [ (mkTuple [ (mkDouble "0.5943236009595587") (mkDouble "-2.063741622941031") ]) ] ])) ]))])
      ] [
        (mkDictionaryEntry ["location" (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Chicago" "KMDW" true [ (mkTuple [ (mkDouble "0.7292712893531614") (mkDouble "-1.5316185371029443") ]) ] [ (mkTuple [ (mkDouble "0.7304208679182801") (mkDouble "-1.529781996944241") ]) ] ])) ]))])
      ] [
        (mkDictionaryEntry ["location" (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "New York" "KNYC" true [ (mkTuple [ (mkDouble "0.7118034407872564") (mkDouble "-1.2909618758762367") ]) ] [ (mkTuple [ (mkDouble "0.7105980465926592") (mkDouble "-1.2916478949920254") ]) ] ])) ]))])
      ] [
        (mkDictionaryEntry ["location" (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "London" "EGWU" true [ (mkTuple [ (mkDouble "0.8997172294030767") (mkDouble "-7.272211034407213e-3") ]) ] [ (mkTuple [ (mkDouble "0.8988445647770796") (mkDouble "-2.0362232784242244e-3") ]) ] ])) ]))])
      ] [
        (mkDictionaryEntry ["location" (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Moscow" "UUWW" true [ (mkTuple [ (mkDouble "0.9712757287348442") (mkDouble "0.6504260403943176") ]) ] [ (mkTuple [ (mkDouble "0.9730598392028181") (mkDouble "0.6565153021683081") ]) ] ])) ]))])
      ] ];
    };

    "org/gnome/clocks/state/window" = {
      maximized = false;
      panel-id = "world";
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///home/tim/Pictures/Wallpapers/blobs-l.svg";
      picture-uri-dark = "file:///home/tim/Pictures/Wallpapers/blobs-d.svg";
      primary-color = "#241f31";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/datetime" = {
      automatic-timezone = false;
    };

    "org/gnome/desktop/input-sources" = {
      current = mkUint32 0;
      mru-sources = [ (mkTuple [ "xkb" "us" ]) ];
      sources = [ (mkTuple [ "xkb" "de+nodeadkeys" ]) ];
      xkb-options = [ "terminate:ctrl_alt_bksp" ];
    };

    "org/gnome/desktop/interface" = {
      clock-show-seconds = false;
      clock-show-weekday = false;
      color-scheme = "prefer-dark";
      enable-animations = true;
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      gtk-theme = "adw-gtk3-dark";
      toolkit-accessibility = false;
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      click-method = "areas";
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/privacy" = {
      old-files-age = mkUint32 30;
      recent-files-max-age = -1;
      report-technical-problems = true;
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///home/tim/Pictures/Wallpapers/blobs-d.svg";
      primary-color = "#241f31";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 900;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":close";
    };

    "org/gnome/evince/default" = {
      continuous = true;
      dual-page = false;
      dual-page-odd-left = true;
      enable-spellchecking = true;
      fullscreen = false;
      inverted-colors = false;
      show-sidebar = true;
      sidebar-page = "thumbnails";
      sidebar-size = 148;
      sizing-mode = "free";
      window-ratio = mkTuple [ (mkDouble "1.0081699346405228") (mkDouble "0.7138445458000761") ];
      zoom = mkDouble "0.5";
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/evolution-data-server/calendar" = {
      reminders-past = [];
    };

    "org/gnome/gnome-system-monitor" = {
      current-tab = "processes";
      network-total-in-bits = false;
      show-dependencies = false;
      show-whose-processes = "user";
    };

    "org/gnome/login-screen" = {
      enable-fingerprint-authentication = true;
      enable-password-authentication = true;
      enable-smartcard-authentication = false;
    };

    "org/gnome/mutter" = {
      center-new-windows = true;
      dynamic-workspaces = true;
      overlay-key = "Super_L";
      workspaces-only-on-primary = true;
    };

    "org/gnome/nautilus/compression" = {
      default-compression-format = "zip";
    };

    "org/gnome/nautilus/icon-view" = {
      captions = [ "none" "none" "none" ];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
      show-create-link = true;
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = mkTuple [ 1398 802 ];
      maximized = false;
    };


    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = 7200;
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = false;
    };


    "org/gnome/shell/extensions/arcmenu" = {
      arc-menu-icon = 71;
      arcmenu-hotkey = [ "Super_R" ];
      custom-menu-button-icon-size = mkDouble "40.0";
      enable-menu-hotkey = false;
      menu-background-color = "rgba(36,36,36,0.85)";
      menu-border-color = "rgb(60,60,60)";
      menu-button-appearance = "Icon";
      menu-button-icon = "Menu_Icon";
      menu-foreground-color = "rgb(223,223,223)";
      menu-item-active-bg-color = "rgb(25,98,163)";
      menu-item-active-fg-color = "rgb(255,255,255)";
      menu-item-hover-bg-color = "rgb(21,83,158)";
      menu-item-hover-fg-color = "rgb(255,255,255)";
      menu-layout = "Eleven";
      menu-separator-color = "rgba(255,255,255,0.1)";
      multi-monitor = false;
      override-menu-theme = true;
      pinned-app-list = [];
      pinned-apps = [ [
        (mkDictionaryEntry ["name" "Firefox Web Browser"])
        (mkDictionaryEntry ["icon" "firefox"])
        (mkDictionaryEntry ["id" "firefox.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Spotify"])
        (mkDictionaryEntry ["icon" "com.spotify.Client"])
        (mkDictionaryEntry ["id" "com.spotify.Client.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Discord"])
        (mkDictionaryEntry ["icon" "discord"])
        (mkDictionaryEntry ["id" "discord.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Steam (Runtime)"])
        (mkDictionaryEntry ["icon" "steam"])
        (mkDictionaryEntry ["id" "steam.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Heroic Games Launcher"])
        (mkDictionaryEntry ["icon" "com.heroicgameslauncher.hgl"])
        (mkDictionaryEntry ["id" "com.heroicgameslauncher.hgl.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Bitwarden"])
        (mkDictionaryEntry ["icon" "com.bitwarden.desktop"])
        (mkDictionaryEntry ["id" "com.bitwarden.desktop.desktop"])
      ] [
        (mkDictionaryEntry ["name" "WhatsApp Desktop"])
        (mkDictionaryEntry ["icon" "io.github.mimbrero.WhatsAppDesktop"])
        (mkDictionaryEntry ["id" "io.github.mimbrero.WhatsAppDesktop.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Geary"])
        (mkDictionaryEntry ["icon" "org.gnome.Geary"])
        (mkDictionaryEntry ["id" "org.gnome.Geary.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Obsidian"])
        (mkDictionaryEntry ["icon" "md.obsidian.Obsidian"])
        (mkDictionaryEntry ["id" "md.obsidian.Obsidian.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Rnote"])
        (mkDictionaryEntry ["icon" "com.github.flxzt.rnote"])
        (mkDictionaryEntry ["id" "com.github.flxzt.rnote.desktop"])
      ] [
        (mkDictionaryEntry ["name" "System Monitor"])
        (mkDictionaryEntry ["icon" "org.gnome.SystemMonitor"])
        (mkDictionaryEntry ["id" "gnome-system-monitor.desktop"])
      ] [
        (mkDictionaryEntry ["name" "Terminal"])
        (mkDictionaryEntry ["icon" "org.gnome.Terminal"])
        (mkDictionaryEntry ["id" "org.gnome.Terminal.desktop"])
      ] ];
      prefs-visible-page = 0;
      search-entry-border-radius = mkTuple [ true 25 ];
      show-activities-button = false;
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = mkDouble "0.6";
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      brightness = mkDouble "0.6";
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      brightness = mkDouble "0.6";
      sigma = 30;
    };

    "org/gnome/shell/extensions/dash-to-panel" = {
      animate-appicon-hover = true;
      animate-appicon-hover-animation-convexity = [
        (mkDictionaryEntry ["RIPPLE" (mkDouble "2.0")])
        (mkDictionaryEntry ["PLANK" (mkDouble "1.0")])
        (mkDictionaryEntry ["SIMPLE" (mkDouble "0.0")])
      ];
      animate-appicon-hover-animation-extent = [
        (mkDictionaryEntry ["RIPPLE" 4])
        (mkDictionaryEntry ["PLANK" 4])
        (mkDictionaryEntry ["SIMPLE" 1])
      ];
      animate-appicon-hover-animation-rotation = [
        (mkDictionaryEntry ["SIMPLE" 0])
        (mkDictionaryEntry ["RIPPLE" 10])
        (mkDictionaryEntry ["PLANK" 0])
      ];
      animate-appicon-hover-animation-travel = [
        (mkDictionaryEntry ["SIMPLE" (mkDouble "0.15")])
        (mkDictionaryEntry ["RIPPLE" (mkDouble "0.4")])
        (mkDictionaryEntry ["PLANK" (mkDouble "0.0")])
      ];
      animate-appicon-hover-animation-type = "SIMPLE";
      appicon-margin = 8;
      appicon-padding = 4;
      available-monitors = [ 1 0 2 ];
      dot-position = "BOTTOM";
      dot-style-focused = "SQUARES";
      dot-style-unfocused = "DOTS";
      hotkeys-overlay-combo = "TEMPORARILY";
      leftbox-padding = -1;
      panel-anchors = ''
        {"0":"MIDDLE","1":"MIDDLE","2":"MIDDLE"}
      '';
      panel-element-positions = ''
        {"0":[{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"showAppsButton","visible":false,"position":"centerMonitor"},{"element":"activitiesButton","visible":true,"position":"stackedTL"},{"element":"rightBox","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"1":[{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":true,"position":"stackedTL"},{"element":"rightBox","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"2":[{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":true,"position":"stackedTL"},{"element":"rightBox","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}
      '';
      panel-element-positions-monitors-sync = false;
      panel-lengths = ''
        {"0":100,"1":100,"2":100}
      '';
      panel-sizes = ''
        {"0":40,"1":48,"2":48}
      '';
      primary-monitor = 1;
      status-icon-padding = -1;
      trans-panel-opacity = mkDouble "0.7000000000000001";
      trans-use-custom-bg = false;
      trans-use-custom-gradient = false;
      trans-use-custom-opacity = true;
      tray-padding = -1;
      window-preview-title-position = "TOP";
    };

    "org/gnome/shell/extensions/ding" = {
      check-x11wayland = true;
      show-home = false;
      show-trash = false;
      show-volumes = false;
    };

    "org/gnome/shell/extensions/gtk4-ding" = {
      add-volumes-opposite = false;
      show-home = false;
      show-link-emblem = false;
      show-trash = false;
      show-volumes = false;
    };

    "org/gnome/shell/extensions/phi" = {
      url1 = "https://pihole.local.yakweide.de/admin/api.php";
    };

    "org/gnome/shell/extensions/sp-tray" = {
      album-max-length = 50;
      artist-max-length = 50;
      display-mode = 0;
      hidden-when-inactive = true;
      hidden-when-paused = false;
      logo-position = 0;
      metadata-when-paused = true;
      paused = "";
      title-max-length = 50;
    };

    "org/gnome/shell/weather" = {
      automatic-location = true;
      locations = [ (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Frankfurt" "EDDF" false [ (mkTuple [ (mkDouble "0.8735372906231619") (mkDouble "0.15009831567151233") ]) ] (mkArray "(dd)" []) ])) ])) (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Frankfurt" "EDDF" true [ (mkTuple [ (mkDouble "0.8735372906231619") (mkDouble "0.15009831567151233") ]) ] [ (mkTuple [ (mkDouble "0.874700849275589") (mkDouble "0.15155275089707676") ]) ] ])) ])) ];
    };

    "org/gnome/shell/world-clocks" = {
      locations = [ (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Los Angeles" "KCQT" true [ (mkTuple [ (mkDouble "0.5937028397045019") (mkDouble "-2.064433611082862") ]) ] [ (mkTuple [ (mkDouble "0.5943236009595587") (mkDouble "-2.063741622941031") ]) ] ])) ])) (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Chicago" "KMDW" true [ (mkTuple [ (mkDouble "0.7292712893531614") (mkDouble "-1.5316185371029443") ]) ] [ (mkTuple [ (mkDouble "0.7304208679182801") (mkDouble "-1.529781996944241") ]) ] ])) ])) (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "New York" "KNYC" true [ (mkTuple [ (mkDouble "0.7118034407872564") (mkDouble "-1.2909618758762367") ]) ] [ (mkTuple [ (mkDouble "0.7105980465926592") (mkDouble "-1.2916478949920254") ]) ] ])) ])) (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "London" "EGWU" true [ (mkTuple [ (mkDouble "0.8997172294030767") (mkDouble "-7.272211034407213e-3") ]) ] [ (mkTuple [ (mkDouble "0.8988445647770796") (mkDouble "-2.0362232784242244e-3") ]) ] ])) ])) (mkVariant (mkTuple [ (mkUint32 2) (mkVariant (mkTuple [ "Moscow" "UUWW" true [ (mkTuple [ (mkDouble "0.9712757287348442") (mkDouble "0.6504260403943176") ]) ] [ (mkTuple [ (mkDouble "0.9730598392028181") (mkDouble "0.6565153021683081") ]) ] ])) ])) ];
    };

    "org/gnome/simple-scan" = {
      save-directory = "file:///home/tim/Documents/Scan";
      save-format = "application/pdf";
    };

    "org/gnome/system/location" = {
      enabled = false;
    };

    "org/gnome/terminal/legacy" = {
      default-show-menubar = false;
    };

    "org/gnome/terminal/legacy/keybindings" = {
      paste = "<Primary>v";
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      background-transparency-percent = 15;
      default-size-columns = 80;
      default-size-rows = 23;
      font = "JetBrainsMono Nerd Font Medium 12";
      use-system-font = false;
      use-transparent-background = true;
    };

    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };

    "org/gtk/gtk4/settings/color-chooser" = {
      custom-colors = [ (mkTuple [ (mkDouble "0.75") (mkDouble "0.25") (mkDouble "0.25") (mkDouble "1.0") ]) (mkTuple [ (mkDouble "0.1411764770746231") (mkDouble "0.1411764770746231") (mkDouble "0.1411764770746231") (mkDouble "0.8533333539962769") ]) (mkTuple [ (mkDouble "0.1411764770746231") (mkDouble "0.1411764770746231") (mkDouble "0.1411764770746231") (mkDouble "0.9133333563804626") ]) (mkTuple [ (mkDouble "0.1882352977991104") (mkDouble "0.1882352977991104") (mkDouble "0.1921568661928177") (mkDouble "0.9800000190734863") ]) ];
      selected-color = mkTuple [ true (mkDouble "0.2078431397676468") (mkDouble "0.5176470875740051") (mkDouble "0.8941176533699036") (mkDouble "1.0") ];
    };

    "org/gtk/gtk4/settings/emoji-chooser" = {
      recent-emoji = [ (mkTuple [ (mkTuple [ [ (mkUint32 128516) ] "grinning face with smiling eyes" [ "eye" "face" "mouth" "open" "smile" ] (mkUint32 0) ]) (mkUint32 0) ]) ];
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 140;
      sort-column = "name";
      sort-directories-first = true;
      sort-order = "ascending";
      type-format = "category";
      view-type = "list";
      window-size = mkTuple [ 859 372 ];
    };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 165;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "descending";
      type-format = "category";
      window-position = mkTuple [ 35 32 ];
      window-size = mkTuple [ 1203 902 ];
    };

    "system/locale" = {
      region = "de_DE.UTF-8";
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [ "ebb4a864-8e0d-4efb-9cf3-396e9b66c109" "5d3de8f3-46d0-44d0-994e-34dcba42ba17" "22213c86-bf18-4d86-a47d-050ddec90177" "b7f1bd08-58dc-44cd-9a8b-439e07678f8f" ];
    };

    "org/gnome/desktop/app-folders/folders/22213c86-bf18-4d86-a47d-050ddec90177" = {
      apps = [ "clion.desktop" "idea-community.desktop" "rust-rover.desktop" "rider.desktop" "code.desktop" "pycharm-community.desktop" "org.qt-project.qtcreator.desktop" "org.gnome.Builder.desktop" ];
      name = "Programming";
    };

    "org/gnome/desktop/app-folders/folders/5d3de8f3-46d0-44d0-994e-34dcba42ba17" = {
      apps = [ "org.gnome.SystemMonitor.desktop" "org.gnome.clocks.desktop" "org.gnome.Totem.desktop" "org.gnome.Music.desktop" "org.wireshark.Wireshark.desktop" "org.gnome.Snapshot.desktop" "simple-scan.desktop" "org.gnome.Calculator.desktop" "org.gnome.TextEditor.desktop" "org.gnome.Maps.desktop" "com.google.Chrome.desktop" "org.filezillaproject.Filezilla.desktop" "com.bitwarden.desktop.desktop" "com.raggesilver.BlackBox.desktop" "org.gnome.Boxes.desktop" "com.github.marhkb.Pods.desktop" "org.cvfosammmm.Setzer.desktop" "org.gnome.Software.desktop" "org.torproject.torbrowser-launcher.desktop" "dev.vencord.Vesktop.desktop" "org.pulseaudio.pavucontrol.desktop" ];
      name = "Applications";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/b7f1bd08-58dc-44cd-9a8b-439e07678f8f" = {
      apps = [ "minecraft-launcher.desktop" "steam.desktop" ];
      name = "Games";
    };

    "org/gnome/desktop/app-folders/folders/ebb4a864-8e0d-4efb-9cf3-396e9b66c109" = {
      apps = [ "org.gnome.Extensions.desktop" "com.mattjakeman.ExtensionManager.desktop" "OpenRGB.desktop" "org.gnome.Weather.desktop" "org.gnome.Loupe.desktop" "org.gnome.DiskUtility.desktop" "org.gnome.baobab.desktop" "org.gnome.Evince.desktop" "org.gnome.Contacts.desktop" "com.github.wwmm.easyeffects.desktop" "org.gnome.Settings.desktop" "com.github.tchx84.Flatseal.desktop" "io.github.Foldex.AdwSteamGtk.desktop" "org.gnome.tweaks.desktop" "org.gnome.World.PikaBackup.desktop" "timeshift-gtk.desktop" ];
      name = "Utilities";
      translate = false;
    };



  "org/gnome/shell" = {
      app-picker-layout = [ [
        (mkDictionaryEntry ["5d3de8f3-46d0-44d0-994e-34dcba42ba17" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 0)])
        ])])
        (mkDictionaryEntry ["22213c86-bf18-4d86-a47d-050ddec90177" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 1)])
        ])])
        (mkDictionaryEntry ["ebb4a864-8e0d-4efb-9cf3-396e9b66c109" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 2)])
        ])])
        (mkDictionaryEntry ["b7f1bd08-58dc-44cd-9a8b-439e07678f8f" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 3)])
        ])])
      ] ];
      enabled-extensions = [ "app-hider@lynith.dev" "appindicatorsupport@rgcjonas.gmail.com" "blur-my-shell@aunetx" "dash-to-panel@jderose9.github.com" "ding@rastersoft.com" "user-theme@gnome-shell-extensions.gcampax.github.com" "sp-tray@sp-tray.esenliyim.github.com" ];
      favorite-apps = [ "org.gnome.Nautilus.desktop" "firefox.desktop" "com.spotify.Client.desktop" "io.github.spacingbat3.webcord.desktop" "com.github.flxzt.rnote.desktop" "org.gnome.Geary.desktop" "org.gnome.Calendar.desktop" "org.gnome.Terminal.desktop" ];
    };
    # org.mozilla.firefox.desktop

    "org/gnome/shell/extensions/app-hider" = {
      hidden-apps = [ "org.gnome.Characters.desktop" "cups.desktop" "org.gnome.font-viewer.desktop" "nvim.desktop" "org.gnome.FileRoller.desktop" "org.gnome.Logs.desktop" "xterm.desktop" "org.gnome.Console.desktop" "org.gnome.seahorse.Application.desktop" "org.gnome.Connections.desktop" "nixos-manual.desktop" "org.torproject.torbrowser-launcher.settings.desktop" "btop.desktop" "julia.desktop" "org.gnome.Console.desktop" ];
      hidden-search-apps = [ "org.gnome.Characters.desktop" "cups.desktop" "org.gnome.font-viewer.desktop" "nvim.desktop" "org.gnome.FileRoller.desktop" "org.gnome.Logs.desktop" "xterm.desktop" "org.gnome.Connections.desktop" "nixos-manual.desktop" "org.torproject.torbrowser-launcher.settings.desktop" "btop.desktop" "julia.desktop" "org.gnome.Console.desktop" "org.gnome.seahorse.Application.desktop" ];
    };

  };
}
