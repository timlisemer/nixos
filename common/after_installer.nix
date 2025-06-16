{
  config,
  pkgs,
  ...
}: let
in {
  # imports
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../secrets/sops.nix
  ];

  # Open ports in the firewall
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable entirely:
  networking = {
    firewall.enable = false;
    wireless.userControlled.enable = true;
    wireless.enable = true;
    wireless.secretsFile = config.sops.secrets."wifiENV".path;
    wireless.networks = {
      # SSID
      BND_Observations_VAN_3 = {
        pskRaw = "ext:home_psk";
        priority = 10;
      };
      Noel = {
        pskRaw = "ext:home2_psk";
        priority = 10;
      };
    };
    networkmanager = {
      enable = true;
      # Tell it to ignore every Wi-Fi interface so it touches only Ethernet
      unmanaged = ["type:wifi"]; # or "interface-name:name" for a single card
    };
  };

  # Google Drive Rclone Mount
  environment.etc."rclone-gdrive.conf".text = ''
    [gdrive]
    type = drive
    client_id = /run/secrets/google_oauth_client_id
    scope = drive
    service_account_file = /run/secrets/google-sa
  '';
  fileSystems."/mnt/gdrive" = {
    device = "gdrive:";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/etc/rclone-gdrive.conf"
      # --- network-related bits ---
      "_netdev" # mark as “needs the network”
      "x-systemd.requires=network-online.target"
      "x-systemd.after=network-online.target"
    ];
  };
  # Cloudflare R2 Rclone Mount
  fileSystems."/mnt/cloudflare" = {
    device = "cloudflare:nixos";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/run/secrets/cloudflare_rclone"
      # --- network-related bits ---
      "_netdev" # mark as “needs the network”
      "x-systemd.requires=network-online.target"
      "x-systemd.after=network-online.target"
    ];
  };
}
