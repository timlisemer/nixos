{ config, pkgs, ... }:

{
  systemd.user.services = {
    webcord = {
      description = "WebCord Discord client";
      wantedBy = [ "default.target" "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        # ExecStart = "${pkgs.flatpak}/bin/flatpak run --branch=stable --arch=x86_64 --env=NODE_OPTIONS=--max-old-space-size=4096 --env=sgx.enclave_size=4G --command=run.sh io.github.spacingbat3.webcord -m";
        ExecStart = "${pkgs.webcord}/bin/webcord -m";
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = "60s";
        StartLimitBurst = "10";
        After = [ "graphical-session.target" "network-online.target" ];
      };
    };

    easyeffects = {
      description = "Easy Effects Service";
      wantedBy = [ "default.target" "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        # ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
        ExecStart = "/bin/easyeffects --gapplication-service";
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = "60s";
        StartLimitBurst = "10";
        After = [ "graphical-session.target" "network-online.target" ];
      };
    };

    geary = {
      description = "Geary email client";
      wantedBy = [ "default.target" "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        # ExecStart = "${pkgs.gnome.geary}/bin/geary --gapplication-service";
        ExecStart = "/bin/geary --gapplication-service";
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = "60s";
        StartLimitBurst = "10";
        After = [ "graphical-session.target" "network-online.target" ];
      };
    };

    pika-backup = {
      description = "Pika Backup";
      wantedBy = [ "default.target" "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.flatpak}/bin/flatpak run --command=pika-backup-monitor org.gnome.World.PikaBackup";
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = "60s";
        StartLimitBurst = "10";
        After = [ "graphical-session.target" "network-online.target" ];
      };
    };

    steam-minimized = {
      description = "Steam (Minimized)";
      wantedBy = [ "default.target" "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${pkgs.steam}/bin/steam -silent";
        Restart = "on-failure";
      };
    };

    whatsapp-for-linux = {
      description = "WhatsApp for Linux";
      wantedBy = [ "default.target" "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        # ExecStart = "${pkgs.whatsapp-for-linux}/bin/whatsapp-for-linux";
        ExecStart = "/bin/whatsapp-for-linux";
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = "60s";
        StartLimitBurst = "10";
        After = [ "graphical-session.target" "network-online.target" ];
      };
    };
  };
}
