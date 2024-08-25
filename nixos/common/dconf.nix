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

    "com/github/Ory0n/Resource_Monitor" = {
      diskdeviceslist = [ "dev /dev false false" "efivarfs /sys/firmware/efi/efivars false false" "/dev/nvme1n1p2 / false false" "/dev/nvme1n1p1 /boot false false" ];
      gpudeviceslist = [ "GPU-3e205fd2-b31f-a112-19af-bf375659fe37:NVIDIA GeForce RTX 3060 Ti:false:false" ];
      thermalcputemperaturedeviceslist = [ "k10temp: Tctl-false-/sys/class/hwmon/hwmon2/temp1_input" "k10temp: Tccd1-false-/sys/class/hwmon/hwmon2/temp3_input" ];
      thermalgputemperaturedeviceslist = [ "GPU-3e205fd2-b31f-a112-19af-bf375659fe37:NVIDIA GeForce RTX 3060 Ti:false" ];
    };

    "com/github/wwmm/easyeffects" = {
      last-used-input-preset = "Presets";
      last-used-output-preset = "Presets";
      window-fullscreen = false;
      window-height = 429;
      window-maximized = false;
      window-width = 722;
    };

    "com/github/wwmm/easyeffects/streaminputs" = {
      input-device = "alsa_input.usb-Startime_Communication._Ltd._KAYSUDA_CA20_000000000000-00.analog-stereo";
    };

    "com/github/wwmm/easyeffects/streamoutputs" = {
      output-device = "alsa_output.usb-Creative_Technology_Ltd_SB_Omni_Surround_5.1_X00000ZT-00.analog-stereo-output";
    };

    "org/gnome/Connections" = {
      first-run = false;
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
      window-height = 1268;
      window-maximize = true;
      window-width = 1720;
    };

    "org/gnome/Snapshot" = {
      is-maximized = false;
      window-height = 640;
      window-width = 800;
    };

    "org/gnome/TextEditor" = {
      last-save-directory = "file:///home/tim/Documents/H_DA/10.Semester/ASP";
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

    "org/gnome/boxes" = {
      first-run = false;
      shared-folders = "[<{'uuid': <'fde80012-ca98-4729-950c-d78bc1c51bda'>, 'path': <'/home/tim/Public'>, 'name': <'hmi'>}>, <{'uuid': <'fde80012-ca98-4729-950c-d78bc1c51bda'>, 'path': <'/home/tim/Public'>, 'name': <'hmi'>}>]";
      view = "icon-view";
      window-maximized = true;
      window-position = [ 35 32 ];
      window-size = [ 768 600 ];
    };

    "org/gnome/calculator" = {
      accuracy = 9;
      angle-units = "degrees";
      base = 10;
      button-mode = "basic";
      number-format = "automatic";
      show-thousands = false;
      show-zeroes = false;
      source-currency = "";
      source-units = "degree";
      target-currency = "";
      target-units = "radian";
      window-maximized = false;
      window-size = mkTuple [ 360 692 ];
      word-size = 64;
    };

    "org/gnome/calendar" = {
      active-view = "month";
      window-maximized = true;
      window-size = mkTuple [ 768 600 ];
    };

    "org/gnome/cheese" = {
      burst-delay = 1000;
      camera = "Integrated RGB Camera (V4L2)";
      photo-x-resolution = 1920;
      photo-y-resolution = 1080;
      selected-effect = "No Effect";
      video-x-resolution = 1920;
      video-y-resolution = 1080;
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
      size = mkTuple [ 870 690 ];
    };

    "org/gnome/control-center" = {
      last-panel = "multitasking";
      window-state = mkTuple [ 1002 634 false ];
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [ "Utilities" "YaST" "Pardus" "fb9d8e27-e2fe-4ccd-adca-b7f0fb2799e5" "2612b819-2b5f-4276-a20a-5fa1eaea2eff" "40df190f-bf6b-4c1d-b2cb-710d2048db31" "f4237030-572d-43b6-b98a-2dc9bf754570" "32fe076c-791e-4ea6-ae2a-7ae9ffdbc64b" ];
    };

    "org/gnome/desktop/app-folders/folders/2612b819-2b5f-4276-a20a-5fa1eaea2eff" = {
      apps = [ "com.nextcloud.desktopclient.nextcloud.desktop" "com.bitwarden.desktop.desktop" "com.github.johnfactotum.Foliate.desktop" "org.gnome.Music.desktop" "io.github.mimbrero.WhatsAppDesktop.desktop" "io.gitlab.news_flash.NewsFlash.desktop" "virtualbox.desktop" "OpenRGB.desktop" "org.gnome.Rhythmbox3.desktop" "org.gnome.Cheese.desktop" "org.gnome.Software.desktop" "io.podman_desktop.PodmanDesktop.desktop" "com.github.marhkb.Pods.desktop" "com.google.Chrome.desktop" "torbrowser.desktop" "io.github.spacingbat3.webcord.desktop" "org.gnome.SystemMonitor.desktop" "org.gnome.Terminal.desktop" "org.torproject.torbrowser-launcher.desktop" "org.filezillaproject.Filezilla.desktop" "org.wireshark.Wireshark.desktop" "steam.desktop" "timeshift-gtk.desktop" "org.gnome.World.PikaBackup.desktop" "kitty.desktop" "dev.vencord.Vesktop.desktop" "org.videolan.VLC.desktop" "com.cassidyjames.butler.desktop" ];
      name = "Apps";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/32fe076c-791e-4ea6-ae2a-7ae9ffdbc64b" = {
      apps = [ "libreoffice-calc.desktop" "libreoffice-writer.desktop" "libreoffice-impress.desktop" "org.cvfosammmm.Setzer.desktop" ];
      name = "Office";
    };

    "org/gnome/desktop/app-folders/folders/40df190f-bf6b-4c1d-b2cb-710d2048db31" = {
      apps = [ "designer.desktop" "code-oss.desktop" "jetbrains-toolbox.desktop" "org.gnome.Builder.desktop" "org.gnome.TextEditor.desktop" "re.sonny.Workbench.desktop" "io.github.java_decompiler.jd-gui.desktop" "rustrover_rustrover.desktop" "pycharm-educational_pycharm-educational.desktop" "webstorm_webstorm.desktop" "clion_clion.desktop" "rider_rider.desktop" "intellij-idea-community_intellij-idea-community.desktop" "code_code.desktop" "com.getpostman.Postman.desktop" "org.qt-project.qtcreator.desktop" "com.jetbrains.CLion.desktop" "jetbrains-rustrover-16ae9fbc-8f5b-40aa-8ada-3541e1f0b9c0.desktop" "jetbrains-clion-6673f66e-4d53-4548-978b-ce7ac149fccc.desktop" "jetbrains-pycharm-c01176c4-5b28-4d59-a26f-3ea4bf571674.desktop" "jetbrains-idea-01365754-38bc-43a2-bdde-e74cdd39b108.desktop" "code.desktop" "jetbrains-rustrover-3455ac52-734e-49f6-9674-63a2b1f65830.desktop" "jetbrains-idea-cae8d121-cc28-4b31-beba-27bf42337153.desktop" "jetbrains-pycharm-553a934d-fc63-46cb-ba01-3c6914b4133a.desktop" "jetbrains-clion-a1a93c49-9115-4bc7-ae84-a4740bf4efb4.desktop" "jetbrains-clion-1309bbd9-5d08-4507-8532-25809e775b8a.desktop" "jetbrains-idea-995f00b7-d631-424d-aaf1-95098355a19c.desktop" "jetbrains-pycharm-ff6fcfa0-53b5-41a3-96cd-d2c8890e9922.desktop" "jetbrains-rustrover-d61ab101-1905-41e4-9f74-e9120a0f7b00.desktop" "cursor.desktop" ];
      name = "Programming";
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [ "gnome-abrt.desktop" "gnome-system-log.desktop" "nm-connection-editor.desktop" "org.gnome.baobab.desktop" "org.gnome.Connections.desktop" "org.gnome.DejaDup.desktop" "org.gnome.Dictionary.desktop" "org.gnome.DiskUtility.desktop" "org.gnome.Evince.desktop" "org.gnome.FileRoller.desktop" "org.gnome.fonts.desktop" "org.gnome.Loupe.desktop" "org.gnome.seahorse.Application.desktop" "org.gnome.tweaks.desktop" "org.gnome.Usage.desktop" "vinagre.desktop" "gnome-system-monitor.desktop" "org.gnome.Settings.desktop" "org.gnome.Weather.desktop" "org.gnome.Totem.desktop" "org.gnome.Snapshot.desktop" "org.gnome.Contacts.desktop" "org.gnome.clocks.desktop" "org.gnome.Maps.desktop" "org.gnome.Calculator.desktop" "simple-scan.desktop" "com.mattjakeman.ExtensionManager.desktop" "ca.desrt.dconf-editor.desktop" "org.fedoraproject.MediaWriter.desktop" "org.gnome.Epiphany.desktop" "org.gnome.Boxes.desktop" "io.github.Foldex.AdwSteamGtk.desktop" "com.github.wwmm.easyeffects.desktop" "com.github.tchx84.Flatseal.desktop" "com.github.liferooter.textpieces.desktop" "io.github.dyegoaurelio.simple-wireplumber-gui.desktop" "org.pulseaudio.pavucontrol.desktop" "org.pipewire.Helvum.desktop" "org.raspberrypi.rpi-imager.desktop" "torbrowser-settings.desktop" "wine-regedit.desktop" "wine-notepad.desktop" "dosbox-staging.desktop" "wine-wineboot.desktop" ];
      categories = [ "X-GNOME-Utilities" ];
      excluded-apps = [ "org.gnome.Tour.desktop" ];
      name = "X-GNOME-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/f4237030-572d-43b6-b98a-2dc9bf754570" = {
      apps = [ "com.heroicgameslauncher.hgl.desktop" "net.lutris.Lutris.desktop" "Banished.desktop" "Hearts of Iron IV.desktop" "Sid Meier's Civilization VI.desktop" "Victoria 3.desktop" "minecraft-launcher.desktop" "Farthest Frontier.desktop" "Horizon Forbidden West Complete Edition.desktop" "Stellaris.desktop" "Europa Universalis IV.desktop" "Total War PHARAOH.desktop" "Counter-Strike 2.desktop" "Grand Theft Auto V.desktop" "Factorio.desktop" ];
      name = "Games";
    };

    "org/gnome/desktop/app-folders/folders/fb9d8e27-e2fe-4ccd-adca-b7f0fb2799e5" = {
      apps = [ "bvnc.desktop" "bssh.desktop" "org.gnome.Extensions.desktop" "avahi-discover.desktop" "qvidcap.desktop" "qv4l2.desktop" "lstopo.desktop" "vim.desktop" "electron25.desktop" "jconsole-java-openjdk.desktop" "jshell-java-openjdk.desktop" "assistant.desktop" "linguist.desktop" "qdbusviewer.desktop" "htop.desktop" "gvim.desktop" ];
      name = "Junk";
      translate = false;
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///usr/share/backgrounds/gnome/blobs-l.svg";
      picture-uri-dark = "file:///usr/share/backgrounds/gnome/blobs-d.svg";
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

    "org/gnome/desktop/notifications" = {
      application-children = [ "org-gnome-software" "com-nextcloud-desktopclient-nextcloud" "firefox" "jetbrains-toolbox" "org-gnome-geary" "com-spotify-client" "steam" "com-discordapp-discord" "gnome-power-panel" "org-gnome-extensions-desktop" "org-gnome-evolution" "io-github-spacingbat3-webcord" "org-gnome-settings" "ckb-next" "org-mozilla-thunderbird" "com-ulduzsoft-birdtray" "discord" "jetbrains-clion-8e1cad27-85f3-48b3-90ae-1503cc39d927" "org-gnome-shell-extensions" "org-gnome-boxes" "webcord" "org-gnome-nautilus" "org-gnome-terminal" "org-gnome-builder" "org-gnome-shell-extensions-gsconnect" "com-heroicgameslauncher-hgl" "gnome-network-panel" "me-kozec-syncthingtk" "org-freedesktop-problems-applet" "rustrover-rustrover" "org-openrgb-openrgb" "org-mozilla-firefox" "webstorm-webstorm" "io-snapcraft-sessionagent" "code-code" "clion-clion" "org-gnome-texteditor" "com-mattjakeman-extensionmanager-desktop" "pycharm-professional-pycharm-professional" "com-github-marhkb-pods" "com-mattjakeman-extensionmanager" "org-qt-project-qtcreator" "org-gnome-calendar" "org-cvfosammmm-setzer" "jetbrains-rustrover-16ae9fbc-8f5b-40aa-8ada-3541e1f0b9c0" "org-gnome-evolution-alarm-notify" "jetbrains-idea-01365754-38bc-43a2-bdde-e74cdd39b108" "com-raggesilver-blackbox" "jetbrains-clion-6673f66e-4d53-4548-978b-ce7ac149fccc" "org-torproject-torbrowser-launcher" "org-wireshark-wireshark" "org-filezillaproject-filezilla" "jetbrains-rustrover-d61ab101-1905-41e4-9f74-e9120a0f7b00" "org-fedoraproject-mediawriter" "kitty" "org-gnome-world-pikabackup" "code-url-handler" "org-gnome-totem" ];
      show-banners = true;
    };

    "org/gnome/desktop/notifications/application/ckb-next" = {
      application-id = "ckb-next.desktop";
    };

    "org/gnome/desktop/notifications/application/clion-clion" = {
      application-id = "clion_clion.desktop";
    };

    "org/gnome/desktop/notifications/application/code-code" = {
      application-id = "code_code.desktop";
    };

    "org/gnome/desktop/notifications/application/code-url-handler" = {
      application-id = "code-url-handler.desktop";
    };

    "org/gnome/desktop/notifications/application/com-discordapp-discord" = {
      application-id = "com.discordapp.Discord.desktop";
    };

    "org/gnome/desktop/notifications/application/com-github-marhkb-pods" = {
      application-id = "com.github.marhkb.Pods.desktop";
    };

    "org/gnome/desktop/notifications/application/com-heroicgameslauncher-hgl" = {
      application-id = "com.heroicgameslauncher.hgl.desktop";
    };

    "org/gnome/desktop/notifications/application/com-mattjakeman-extensionmanager-desktop" = {
      application-id = "com.mattjakeman.ExtensionManager.desktop.desktop";
    };

    "org/gnome/desktop/notifications/application/com-mattjakeman-extensionmanager" = {
      application-id = "com.mattjakeman.ExtensionManager.desktop";
    };

    "org/gnome/desktop/notifications/application/com-nextcloud-desktopclient-nextcloud" = {
      application-id = "com.nextcloud.desktopclient.nextcloud.desktop";
      enable = false;
    };

    "org/gnome/desktop/notifications/application/com-raggesilver-blackbox" = {
      application-id = "com.raggesilver.BlackBox.desktop";
    };

    "org/gnome/desktop/notifications/application/com-spotify-client" = {
      application-id = "com.spotify.Client.desktop";
      enable = false;
      show-banners = true;
    };

    "org/gnome/desktop/notifications/application/com-ulduzsoft-birdtray" = {
      application-id = "com.ulduzsoft.Birdtray.desktop";
    };

    "org/gnome/desktop/notifications/application/discord" = {
      application-id = "discord.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/firefox" = {
      application-id = "firefox.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/gnome-network-panel" = {
      application-id = "gnome-network-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/io-github-spacingbat3-webcord" = {
      application-id = "io.github.spacingbat3.webcord.desktop";
    };

    "org/gnome/desktop/notifications/application/io-snapcraft-sessionagent" = {
      application-id = "io.snapcraft.SessionAgent.desktop";
    };

    "org/gnome/desktop/notifications/application/jetbrains-clion-6673f66e-4d53-4548-978b-ce7ac149fccc" = {
      application-id = "jetbrains-clion-6673f66e-4d53-4548-978b-ce7ac149fccc.desktop";
    };

    "org/gnome/desktop/notifications/application/jetbrains-clion-8e1cad27-85f3-48b3-90ae-1503cc39d927" = {
      application-id = "jetbrains-clion-8e1cad27-85f3-48b3-90ae-1503cc39d927.desktop";
    };

    "org/gnome/desktop/notifications/application/jetbrains-idea-01365754-38bc-43a2-bdde-e74cdd39b108" = {
      application-id = "jetbrains-idea-01365754-38bc-43a2-bdde-e74cdd39b108.desktop";
    };

    "org/gnome/desktop/notifications/application/jetbrains-rustrover-16ae9fbc-8f5b-40aa-8ada-3541e1f0b9c0" = {
      application-id = "jetbrains-rustrover-16ae9fbc-8f5b-40aa-8ada-3541e1f0b9c0.desktop";
    };

    "org/gnome/desktop/notifications/application/jetbrains-rustrover-d61ab101-1905-41e4-9f74-e9120a0f7b00" = {
      application-id = "jetbrains-rustrover-d61ab101-1905-41e4-9f74-e9120a0f7b00.desktop";
    };

    "org/gnome/desktop/notifications/application/jetbrains-toolbox" = {
      application-id = "jetbrains-toolbox.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/kitty" = {
      application-id = "kitty.desktop";
    };

    "org/gnome/desktop/notifications/application/me-kozec-syncthingtk" = {
      application-id = "me.kozec.syncthingtk.desktop";
    };

    "org/gnome/desktop/notifications/application/org-cvfosammmm-setzer" = {
      application-id = "org.cvfosammmm.Setzer.desktop";
    };

    "org/gnome/desktop/notifications/application/org-fedoraproject-mediawriter" = {
      application-id = "org.fedoraproject.MediaWriter.desktop";
    };

    "org/gnome/desktop/notifications/application/org-filezillaproject-filezilla" = {
      application-id = "org.filezillaproject.Filezilla.desktop";
    };

    "org/gnome/desktop/notifications/application/org-freedesktop-problems-applet" = {
      application-id = "org.freedesktop.problems.applet.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-boxes" = {
      application-id = "org.gnome.Boxes.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/org-gnome-builder" = {
      application-id = "org.gnome.Builder.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-calendar" = {
      application-id = "org.gnome.Calendar.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-clocks" = {
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/org-gnome-evolution-alarm-notify" = {
      application-id = "org.gnome.Evolution-alarm-notify.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-evolution" = {
      application-id = "org.gnome.Evolution.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-extensions-desktop" = {
      application-id = "org.gnome.Extensions.desktop.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-geary" = {
      application-id = "org.gnome.Geary.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/org-gnome-nautilus" = {
      application-id = "org.gnome.Nautilus.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-settings" = {
      application-id = "org.gnome.Settings.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-shell-extensions-gsconnect" = {
      application-id = "org.gnome.Shell.Extensions.GSConnect.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-shell-extensions" = {
      application-id = "org.gnome.Shell.Extensions.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-software" = {
      application-id = "org.gnome.Software.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/org-gnome-terminal" = {
      application-id = "org.gnome.Terminal.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/org-gnome-texteditor" = {
      application-id = "org.gnome.TextEditor.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-totem" = {
      application-id = "org.gnome.Totem.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-world-pikabackup" = {
      application-id = "org.gnome.World.PikaBackup.desktop";
    };

    "org/gnome/desktop/notifications/application/org-mozilla-firefox" = {
      application-id = "org.mozilla.firefox.desktop";
    };

    "org/gnome/desktop/notifications/application/org-mozilla-thunderbird" = {
      application-id = "org.mozilla.Thunderbird.desktop";
    };

    "org/gnome/desktop/notifications/application/org-openrgb-openrgb" = {
      application-id = "org.openrgb.OpenRGB.desktop";
    };

    "org/gnome/desktop/notifications/application/org-qt-project-qtcreator" = {
      application-id = "org.qt-project.qtcreator.desktop";
    };

    "org/gnome/desktop/notifications/application/org-torproject-torbrowser-launcher" = {
      application-id = "org.torproject.torbrowser-launcher.desktop";
    };

    "org/gnome/desktop/notifications/application/org-wireshark-wireshark" = {
      application-id = "org.wireshark.Wireshark.desktop";
    };

    "org/gnome/desktop/notifications/application/pycharm-professional-pycharm-professional" = {
      application-id = "pycharm-professional_pycharm-professional.desktop";
    };

    "org/gnome/desktop/notifications/application/rustrover-rustrover" = {
      application-id = "rustrover_rustrover.desktop";
    };

    "org/gnome/desktop/notifications/application/steam" = {
      application-id = "steam.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/webcord" = {
      application-id = "webcord.desktop";
      details-in-lock-screen = true;
      force-expanded = true;
    };

    "org/gnome/desktop/notifications/application/webstorm-webstorm" = {
      application-id = "webstorm_webstorm.desktop";
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
      picture-uri = "file:///usr/share/backgrounds/gnome/blobs-l.svg";
      primary-color = "#241f31";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 900;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":close";
    };

    "org/gnome/epiphany" = {
      ask-for-default = false;
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
      maximized = true;
      network-total-in-bits = false;
      show-dependencies = false;
      show-whose-processes = "user";
      window-state = mkTuple [ 2560 1392 1920 0 ];
    };

    "org/gnome/gnome-system-monitor/disktreenew" = {
      col-6-visible = true;
      col-6-width = 0;
    };

    "org/gnome/gnome-system-monitor/proctree" = {
      columns-order = [ 0 1 2 3 4 6 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 ];
      sort-col = 26;
      sort-order = 1;
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

    "org/gnome/nm-applet/eap/5a9361ad-da73-4522-808e-1fa1c685a2ae" = {
      ignore-ca-cert = false;
      ignore-phase2-ca-cert = false;
    };

    "org/gnome/nm-applet/eap/69852dd1-44e8-4d31-80ea-c93671d63999" = {
      ignore-ca-cert = true;
      ignore-phase2-ca-cert = false;
    };

    "org/gnome/portal/filechooser/com/discordapp/Discord" = {
      last-folder-path = "/home/tim/Pictures/Kagge";
    };

    "org/gnome/portal/filechooser/com/github/flxzt/rnote" = {
      last-folder-path = "/home/tim/.Nextcloud/Notes/RNote/H-DA";
    };

    "org/gnome/portal/filechooser/com/heroicgameslauncher/hgl" = {
      last-folder-path = "/home/tim/Games/Save Games";
    };

    "org/gnome/portal/filechooser/cursor" = {
      last-folder-path = "/home/tim/Coding/IdeSaves/VisualStudioCode/youtube-tv-for-electron";
    };

    "org/gnome/portal/filechooser/firefox" = {
      last-folder-path = "/home/tim/Pictures/Kagge";
    };

    "org/gnome/portal/filechooser/io/github/spacingbat3/webcord" = {
      last-folder-path = "/home/tim/Pictures/Kagge";
    };

    "org/gnome/portal/filechooser/io/gitlab/news_flash/NewsFlash" = {
      last-folder-path = "/home/tim/Coding/Other/Rss";
    };

    "org/gnome/portal/filechooser/md/obsidian/Obsidian" = {
      last-folder-path = "/home/tim/.Nextcloud/Notes/Obsidian";
    };

    "org/gnome/portal/filechooser/org/cvfosammmm/Setzer" = {
      last-folder-path = "/home/tim/Documents/H_DA/10.Semester/wai2/short-paper";
    };

    "org/gnome/portal/filechooser/org/fedoraproject/MediaWriter" = {
      last-folder-path = "/home/tim/Downloads";
    };

    "org/gnome/portal/filechooser/org/gnome/Boxes" = {
      last-folder-path = "/home/tim/Downloads";
    };

    "org/gnome/portal/filechooser/org/gnome/Builder" = {
      last-folder-path = "/home/tim/Coding/IdeSaves/Builder";
    };

    "org/gnome/portal/filechooser/org/gnome/Settings" = {
      last-folder-path = "/home/tim/Downloads";
    };

    "org/gnome/portal/filechooser/org/gnome/World/PikaBackup" = {
      last-folder-path = "/home/tim/Games/Storage";
    };

    "org/gnome/portal/filechooser/simple-scan" = {
      last-folder-path = "/home/tim/Documents/Dokumente/Tim/Arbeit/Iocto";
    };

    "org/gnome/portal/filechooser/steam" = {
      last-folder-path = "/home/tim/Games/Storage/Steam";
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-last-coordinates = mkTuple [ (mkDouble "50.02706605540825") (mkDouble "8.8812") ];
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = 7200;
    };

    "org/gnome/shell" = {
      app-picker-layout = [ [
        (mkDictionaryEntry ["2612b819-2b5f-4276-a20a-5fa1eaea2eff" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 0)])
        ])])
        (mkDictionaryEntry ["40df190f-bf6b-4c1d-b2cb-710d2048db31" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 1)])
        ])])
        (mkDictionaryEntry ["32fe076c-791e-4ea6-ae2a-7ae9ffdbc64b" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 2)])
        ])])
        (mkDictionaryEntry ["Utilities" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 3)])
        ])])
        (mkDictionaryEntry ["f4237030-572d-43b6-b98a-2dc9bf754570" (mkVariant [
          (mkDictionaryEntry ["position" (mkVariant 4)])
        ])])
      ] ];
      command-history = [ "r" ];
      disable-user-extensions = false;
      disabled-extensions = [ "just-perfection-desktop@just-perfection" "native-window-placement@gnome-shell-extensions.gcampax.github.com" "system-monitor-indicator@mknap.com" "System_Monitor@bghome.gmail.com" "auto-move-windows@gnome-shell-extensions.gcampax.github.com" "arcmenu@arcmenu.com" ];
      enabled-extensions = [ "appindicatorsupport@rgcjonas.gmail.com" "blur-my-shell@aunetx" "ControlBlurEffectOnLockScreen@pratap.fastmail.fm" "ding@rastersoft.com" "sp-tray@sp-tray.esenliyim.github.com" "user-theme@gnome-shell-extensions.gcampax.github.com" "weatherornot@somepaulo.github.io" "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com" "chatgpt-gnome-desktop@chatgpt-gnome-desktop" "windowIsReady_Remover@nunofarruca@gmail.com" "gsconnect@andyholmes.github.io" "arch-update@RaphaelRochet" "Resource_Monitor@Ory0n" "monitor@astraext.github.io" "gtk4-ding@smedius.gitlab.com" "phi@ziyagenc.github.com" "app-hider@lynith.dev" "dash-to-panel@jderose9.github.com" ];
      favorite-apps = [ "org.gnome.Nautilus.desktop" "org.mozilla.firefox.desktop" "com.spotify.Client.desktop" "io.github.spacingbat3.webcord.desktop" "com.github.flxzt.rnote.desktop" "org.gnome.Geary.desktop" "com.raggesilver.BlackBox.desktop" "org.gnome.Calendar.desktop" ];
      last-selected-power-profile = "power-saver";
      remember-mount-password = true;
      welcome-dialog-last-shown-version = "45.1";
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = false;
    };

    "org/gnome/shell/extensions/app-hider" = {
      hidden-apps = [ "fish.desktop" "nvim.desktop" "Proton Hotfix.desktop" "Steam Linux Runtime 3.0 (sniper).desktop" "Proton Experimental.desktop" "syncthing-ui.desktop" "syncthing-start.desktop" "java-17-openjdk-17.0.9.0.9-3.fc39.x86_64-jconsole.desktop" "julia.desktop" "nvidia-settings.desktop" "yelp.desktop" "org.gnome.Tour.desktop" "btop.desktop" "discord_minimized.desktop" "Proton 9.0.desktop" "steam_minimized.desktop" "org.torproject.torbrowser-launcher.settings.desktop" "wine-regedit.desktop" "wine-notepad.desktop" "dosbox-staging.desktop" "wine-winecfg.desktop" "wine-winefile.desktop" "wine-winhelp.desktop" "wine-oleview.desktop" "wine-uninstaller.desktop" "wine-wordpad.desktop" "wine-winemine.desktop" "wine-wineboot.desktop" "nwg-panel-config.desktop" ];
      hidden-search-apps = [ "fish.desktop" "Proton Hotfix.desktop" "Steam Linux Runtime 3.0 (sniper).desktop" "nvim.desktop" "Proton Experimental.desktop" "syncthing-start.desktop" "qt5-linguist.desktop" "java-17-openjdk-17.0.9.0.9-3.fc39.x86_64-jconsole.desktop" "julia.desktop" "org.gnome.Tour.desktop" "nvidia-settings.desktop" "yelp.desktop" "btop.desktop" "discord_minimized.desktop" "Proton 9.0.desktop" "steam_minimized.desktop" "org.torproject.torbrowser-launcher.settings.desktop" "wine-regedit.desktop" "wine-notepad.desktop" "dosbox-staging.desktop" "wine-winecfg.desktop" "wine-winefile.desktop" "wine-winhelp.desktop" "wine-oleview.desktop" "wine-uninstaller.desktop" "wine-wordpad.desktop" "wine-winemine.desktop" "wine-wineboot.desktop" ];
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
      recently-installed-apps = [ "electron25.desktop" "jshell-java-openjdk.desktop" "jconsole-java-openjdk.desktop" "designer.desktop" "cmake-gui.desktop" "assistant.desktop" "qdbusviewer.desktop" "linguist.desktop" "ckb-next.desktop" "jetbrains-rustrover-98f49aa2-9b57-43e5-ae27-057f32eb2bc7.desktop" "jetbrains-pycharm-cde97794-b6d2-41aa-9549-f3e101ca1824.desktop" "jetbrains-clion-8e1cad27-85f3-48b3-90ae-1503cc39d927.desktop" "Victoria 3.desktop" "Hearts of Iron IV.desktop" "Counter-Strike 2.desktop" "steam-native.desktop" "gnome-nettool.desktop" "org.gnome.MultiWriter.desktop" "org.gnome.Usage.desktop" "org.gnome.Console.desktop" "org.gnome.Evolution.desktop" "Sid Meier's Civilization VI.desktop" "Rocket League.desktop" "org.pipewire.Helvum.desktop" "Crusader Kings III.desktop" "com.ulduzsoft.Birdtray.desktop" "org.mozilla.Thunderbird.desktop" "OpenRGB.desktop" "com.jetbrains.toolbox-app.desktop" "io.github.java_decompiler.jd-gui.desktop" "ca.desrt.dconf-editor.desktop" "com.jetbrains.PyCharm-Professional.desktop" "jetbrains-clion-03277d21-fad5-45b6-b449-6d4486649237.desktop" "re.sonny.Workbench.desktop" "org.gnome.seahorse.Application.desktop" "org.gnome.World.PikaBackup.desktop" "com.hunterwittenborn.Celeste.desktop" "com.github.wwmm.easyeffects.desktop" "virtualbox.desktop" "ffado-mixer.desktop" "io.github.dyegoaurelio.simple-wireplumber-gui.desktop" "re.sonny.Junction.desktop" "htop.desktop" "org.openrgb.OpenRGB.desktop" "net.lutris.Lutris.desktop" "Banished.desktop" "me.kozec.syncthingtk.desktop" "com.nextcloud.desktopclient.nextcloud.desktop" "minecraft-launcher.desktop" "nvim.desktop" "snap-store_snap-store.desktop" "pycharm-educational_pycharm-educational.desktop" "webstorm_webstorm.desktop" "rider_rider.desktop" "intellij-idea-community_intellij-idea-community.desktop" "Steam Linux Runtime 3.0 (sniper).desktop" "Horizon Forbidden West Complete Edition.desktop" "Proton Hotfix.desktop" "Proton Experimental.desktop" "Farthest Frontier.desktop" "qt5-linguist.desktop" "julia.desktop" "java-17-openjdk-17.0.9.0.9-3.fc39.x86_64-jconsole.desktop" "com.github.marhkb.Pods.desktop" "Stellaris.desktop" "Europa Universalis IV.desktop" "torbrowser-settings.desktop" "com.jetbrains.CLion.desktop" "com.google.Chrome.desktop" "io.github.spacingbat3.webcord.desktop" "org.gnome.Snapshot.desktop" "io.gitlab.news_flash.NewsFlash.desktop" "mupdf-gl.desktop" "org.fontforge.FontForge.desktop" "io.github.vectorgraphics.asymptote.desktop" "org.inkscape.Inkscape.desktop" "jetbrains-clion-6673f66e-4d53-4548-978b-ce7ac149fccc.desktop" "com.github.tchx84.Flatseal.desktop" "steam_minimized.desktop" "Grand Theft Auto V.desktop" "discord_minimized.desktop" "Total War PHARAOH.desktop" "jetbrains-idea-da9cb7e8-a996-4a66-8a32-730dd7cffbe2.desktop" "jetbrains-clion-20b387bf-051c-4534-87a4-f57aeeb6c5a0.desktop" "jetbrains-pycharm-8057d945-aadc-4618-ab06-fd348021d403.desktop" "jetbrains-rustrover-df303abb-0d31-405b-8af1-4762717d4815.desktop" "Proton 9.0.desktop" "com.getpostman.Postman.desktop" "btop.desktop" "jetbrains-toolbox.desktop" ];
      search-entry-border-radius = mkTuple [ true 25 ];
      show-activities-button = false;
    };

    "org/gnome/shell/extensions/astra-monitor" = {
      memory-indicators-order = "[\"icon\",\"bar\",\"graph\",\"percentage\",\"value\"]";
      monitors-order = "[\"processor\",\"memory\",\"storage\",\"network\",\"sensors\"]";
      network-indicators-order = "[\"icon\",\"IO bar\",\"IO graph\",\"IO speed\"]";
      processor-indicators-order = "[\"icon\",\"bar\",\"graph\",\"percentage\"]";
      sensors-indicators-order = "[\"icon\",\"value\"]";
      storage-indicators-order = "[\"icon\",\"bar\",\"percentage\",\"IO bar\",\"IO graph\",\"IO speed\"]";
      storage-main = "eui.0025385311907eb7-part2";
    };

    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [ "com.spotify.Client.desktop:2" "discord.desktop:2" ];
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = mkDouble "0.6";
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = mkDouble "0.6";
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0;
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
      save-directory = "file:///home/tim/Documents/Dokumente/Tim/Arbeit/Iocto/";
      save-format = "application/pdf";
    };

    "org/gnome/software" = {
      check-timestamp = mkInt64 1724515364;
      first-run = false;
      flatpak-purge-timestamp = mkInt64 1724550885;
      install-timestamp = mkInt64 1723547261;
      packagekit-historical-updates-timestamp = mkUint64 1723547261;
      security-timestamp = mkInt64 1723547144308046;
      update-notification-timestamp = mkInt64 1723547325;
      upgrade-notification-timestamp = mkInt64 1713997422;
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

  };
}
