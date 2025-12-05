{
  config,
  pkgs,
  inputs,
  hostName,
  ...
}: {
  # sops encryption settings
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.sshKeyPaths = ["/etc/ssh/nixos_personal_sops_key"];
  # sops.age.keyFile      = "/home/tim/.config/sops/age/keys.txt";
  # sops.age.generateKey  = true;

  sops.secrets.github_token = {};
  sops.secrets.google_oauth_client_id = {};
  sops.secrets.vaultwardenEnv = {};
  sops.secrets.traefikENV = {};
  sops.secrets.yakweideENV = {};
  sops.secrets.piholePWD = {};
  sops.secrets.immichENV = {};
  sops.secrets.wifiENV = {};
  sops.secrets.amazon_client_id = {};
  sops.secrets.amazon_client_secret = {};
  sops.secrets.webhook_id_audio_receiver = {
    mode = "0444"; # Readable by GNOME extension
  };
  sops.secrets.cloudflare_rclone = {};
  sops.secrets.google-sa = {
    sopsFile = ./secrets.yaml;
    key = "google_drive_sa_json";
    path = "/run/secrets/google-sa";
    # restartUnits = ["rclone-gdrive.mount"]; # auto-reload after key rotation
  };
  sops.secrets.resticENV = {};

  sops.secrets.openvpn_ca = {owner = "nm-openvpn";};
  sops.secrets.openvpn_extra_certs = {group = "nm-openvpn";};
  sops.secrets.openvpn_cert = {group = "nm-openvpn";};
  sops.secrets.openvpn_key = {group = "nm-openvpn";};
  sops.secrets.openvpn_ta = {group = "nm-openvpn";};

  # WireGuard Home VPN secrets
  sops.secrets.wireguard_home_private_key = {};
  sops.secrets.wireguard_home_preshared_key = {};

  # Template for WireGuard environment variables
  sops.templates."wireguardENV" = {
    owner = "root";
    mode = "0400";
    content = ''
      WG_HOME_PRIVATE_KEY=${config.sops.placeholder.wireguard_home_private_key}
      WG_HOME_PRESHARED_KEY=${config.sops.placeholder.wireguard_home_preshared_key}
    '';
  };
}
