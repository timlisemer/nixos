{
  # Enable Flatpaks
  services.flatpak = {
    enable = true;
  };

  services.flatpak.remotes = {
    "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  };

  services.flatpak.packages = [
    "flathub:app/com.github.tchx84.Flatseal//stable"
    "flathub:app/com.cassidyjames.butler//stable"
    "flathub:app/com.bitwarden.desktop//stable"
    "flathub:app/com.discordapp.Discord//stable"
    "flathub:app/com.github.marhkb.Pods//stable"
    "flathub:app/com.protonvpn.www//stable"
    # "flathub:app/com.spotify.Client//stable"
    # "flathub:app/dev.vencord.Vesktop//stable"
    # "flathub:app/io.github.Foldex.AdwSteamGtk//stable"
    # "flathub:app/io.github.spacingbat3.webcord//stable"
    "flathub:app/org.filezillaproject.Filezilla//stable"
    "flathub:app/org.gnome.Builder//stable"
    "flathub:app/org.pulseaudio.pavucontrol//stable"
    "flathub:app/org.torproject.torbrowser-launcher//stable"
    # "flathub:app/org.mozilla.firefox//stable"
    "flathub:app/org.raspberrypi.rpi-imager//stable"
    "flathub:app/com.github.Matoking.protontricks//stable"
  ];
}
