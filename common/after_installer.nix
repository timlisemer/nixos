{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: let
in {
  # imports
  imports = [
    # Inline module that turns on Wake-on-LAN for every interface
    ({lib, ...}: {
      options.networking.interfaces = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submoduleWith {
          modules = [
            ({name, ...}: {
              config.wakeOnLan.enable = lib.mkDefault true;
            })
          ];
        });
      };
    })
    inputs.sops-nix.nixosModules.sops
    ../secrets/sops.nix
  ];

  # Open ports in the firewall
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable entirely:
  networking = {
    firewall.enable = false;
    networkmanager.enable = true;

    networkmanager.ensureProfiles.environmentFiles = [
      "/run/secrets/wifiENV"
    ];

    networkmanager.ensureProfiles.profiles = {
      "BND_Observations_Van_3" = {
        connection = {
          id = "BND_Observations_Van_3";
          type = "wifi";
          autoconnect = true;
        };

        wifi = {
          ssid = "BND_Observations_Van_3";
          mode = "infrastructure";
        };

        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$HOME_WIFI_PSK"; # substituted from env file
        };

        ipv4 = {method = "auto";};
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
      };
      "Noel" = {
        connection = {
          id = "Noel";
          type = "wifi";
          autoconnect = true;
        };

        wifi = {
          ssid = "Noel";
          mode = "infrastructure";
        };

        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$HOME2_WIFI_PSK"; # substituted from env file
        };

        ipv4 = {method = "auto";};
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
      };
    };
  };

  # Google Drive Rclone Mount
  environment.etc."rclone-gdrive.conf".text = lib.mkForce ''
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
