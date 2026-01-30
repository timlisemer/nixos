{
  config,
  pkgs,
  inputs,
  lib,
  backupPaths,
  hostName,
  ...
}: {
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
    ../services/restic_backups.nix
  ];

  services.avahi = {
    enable = true;
    nssmdns4 = true; # Use mdns_minimal for .local name resolution (IPv4)
    nssmdns6 = true; # Use mdns_minimal for .local name resolution (IPv6)
    openFirewall = true; # Allow mDNS traffic through the firewall -> UDP port 5353 for mDNS multicast traffic
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    # This is crucial: It ensures mDNS packets are correctly routed
    # between the physical interface (end0) and any virtual interfaces.
    reflector = true;
  };

  # Disable systemd-resolved to prevent conflicts with Avahi mDNS
  services.resolved.enable = false;

  # Open ports in the firewall
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable entirely:
  networking = {
    networkmanager.enable = true;

    networkmanager.plugins = with pkgs; [
      networkmanager-openvpn
    ];

    networkmanager.settings = {
      connection = {
        mdns = 2; # Enables full mDNS resolution and publishing for .local domains. 0 = disabled, 1 = enabled, 2 = enabled and managed by Avahi
      };
    };

    firewall = lib.mkForce {
      enable = true;

      # TCP ports to open
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP / Traefik
        443 # HTTPS / Traefik
        3000 # Personal dev port
      ];

      # UDP ports to open
      allowedUDPPorts = [
        5353 # Multicast DNS (mDNS)
      ];

      # ICMP (ping) is allowed separately
      allowPing = true;
    };

    networkmanager.ensureProfiles.environmentFiles = [
      "/run/secrets/wifiENV"
      "/run/secrets/rendered/wireguardENV"
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
      "iocto_guest" = {
        connection = {
          id = "iocto_guest";
          type = "wifi";
          autoconnect = true;
        };

        wifi = {
          ssid = "iocto_guest";
          mode = "infrastructure";
        };

        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$IOCTO_WIFI_PSK"; # substituted from env file
        };

        ipv4 = {method = "auto";};
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
      };
      "Work-VPN" = {
        connection = {
          id = "Work-VPN";
          type = "vpn";
          autoconnect = false;
        };

        vpn = {
          service-type = "org.freedesktop.NetworkManager.openvpn";
          connection-type = "password-tls";

          remote = "vpn1.kr.iocto.com";
          port = "1196";
          # remote-random = "yes"; # second host handled by random fallback

          dev-type = "tun";
          auth = "SHA256";
          remote-cert-tls = "server";
          verify-x509-name = "name:iocto OpenVPN Automation Server";
          ca = "/run/secrets/openvpn_ca";
          extra-certs = "/run/secrets/openvpn_extra_certs";
          cert = "/run/secrets/openvpn_cert";
          key = "/run/secrets/openvpn_key";
          ta = "/run/secrets/openvpn_ta";

          ping = "10";
          ping-restart = "60";
          reneg-seconds = "0";
          password-flags = "2";
          username = "tlisemer";
          connect-timeout = "15";
        };

        ipv4 = {
          method = "auto";
          # ignore-auto-dns = false; # accept the DNS servers sent by the VPN
          ignore-auto-dns = true; # ignore the DNS servers sent by the VPN
          never-default = true; # keep the local default route
          dns = "172.16.2.254;172.22.0.2;172.22.0.3;1.1.1.1;8.8.8.8";
        };
        ipv6 = {
          # addr-gen-mode = "default";
          ignore-auto-dns = true; # ignore the DNS servers sent by the VPN
          method = "auto";
          dns = "fec0:0:0:ffff::1;fec0:0:0:ffff::2;fec0:0:0:ffff::3";
        };
      };
      "Home" = {
        connection = {
          id = "Home";
          type = "wireguard";
          interface-name = "wg-home";
          autoconnect = false;
        };

        wireguard = {
          private-key = "$WG_HOME_PRIVATE_KEY";
        };

        "wireguard-peer.KurEHrUhn1j117Abf4ESMMqAwm5YO1QiGe/jeY+OcTs=" = {
          endpoint = "odalb8joqto3nnev.myfritz.net:57189";
          persistent-keepalive = "25";
          allowed-ips = "10.0.0.0/8;192.168.178.0/24;fdb3:10a8:8234::/64";
          preshared-key = "$WG_HOME_PRESHARED_KEY";
        };

        ipv4 = {
          address1 = "10.2.0.0/8";
          method = "manual";
          dns = "10.0.0.2;10.0.0.1;192.168.178.1";
          dns-search = "fritz.box";
        };
        ipv6 = {
          address1 = "fdb3:10a8:8234::201/64";
          method = "manual";
          dns = "2a02:908:df57:3f20:2459:6285:7898:12ac;fdb3:10a8:8234::2e91:abff:fe85:a0e1";
        };
      };
    };
  };

  # Google Drive Rclone Mount
  #environment.
  #etc."rclone-gdrive.conf".text = lib.mkForce ''
  #  [gdrive]
  #  type = drive
  #  client_id = /run/secrets/google_oauth_client_id
  #  scope = drive
  #  service_account_file = /run/secrets/google-sa
  #'';
  #fileSystems."/mnt/gdrive" = {
  #  device = "gdrive:";
  #  fsType = "rclone";
  #  options = [
  #    "nodev"
  #    "nofail"
  #    "allow_other"
  #    "args2env"
  #    "config=/etc/rclone-gdrive.conf"
  #    # --- network-related bits ---
  #    "_netdev" # mark as “needs the network”
  #    "x-systemd.requires=network-online.target"
  #    "x-systemd.after=network-online.target"
  #  ];
  #};

  # S3-compatible Object Storage (rclone)
  fileSystems."/mnt/offsite-data" = {
    device = "cloudflare:nixos";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/run/secrets/rclone_s3"
      # --- network-related bits ---
      "_netdev" # mark as "needs the network"
      "x-systemd.requires=network-online.target"
      "x-systemd.after=network-online.target"
    ];
  };

  # Helper scripts
  environment.systemPackages = with pkgs;
    lib.mkAfter [
      # --- install_keys ---------------------------------------------------------
      (pkgs.writeShellScriptBin "install_keys" ''
        #! /usr/bin/env bash
        set -euo pipefail
        trap 'ret=$?; echo "install_keys failed at line $LINENO (exit $ret)" >&2; exit $ret' ERR

        HOME="/home/$USER"
        PRIMARY_KEY_PATH="$HOME/.ssh/id_ed25519"
        SOPS_KEY_PATH="/etc/ssh/nixos_personal_sops_key"
        AGE_KEYS_DIR="$HOME/.config/sops/age"
        AGE_KEYS_PATH="$AGE_KEYS_DIR/keys.txt"

        echo "Checking for primary SSH key…"
        [[ -f "$PRIMARY_KEY_PATH" ]] || { echo "Missing $PRIMARY_KEY_PATH" >&2; exit 1; }

        # Skip work when everything is already there
        if [[ -f "$SOPS_KEY_PATH" && -f "$AGE_KEYS_PATH" ]]; then
          echo "All keys already present - nothing to do."
          exit 0
        fi

        echo "Generating missing keys…"

        if [[ ! -f "$SOPS_KEY_PATH" ]]; then
          echo " → creating $SOPS_KEY_PATH (sudo)…"
          sudo cp "$PRIMARY_KEY_PATH" "$SOPS_KEY_PATH"
        fi

        if [[ ! -f "$AGE_KEYS_PATH" ]]; then
          echo " → creating $AGE_KEYS_PATH"
          command -v ssh-to-age >/dev/null 2>&1 || { echo "ssh-to-age not found" >&2; exit 1; }
          mkdir -p "$AGE_KEYS_DIR"
          ssh-to-age -private-key -i "$PRIMARY_KEY_PATH" >"$AGE_KEYS_PATH"
        fi

        echo "Fixing ownership/permissions…"
        sudo chown root:root "$SOPS_KEY_PATH"
        sudo chmod 600      "$SOPS_KEY_PATH"
        chown  -R "$USER:users" "$HOME/.config/sops"
        chmod 700 "$AGE_KEYS_DIR"
        chmod 600 "$AGE_KEYS_PATH"
        chmod 700 "$HOME/.ssh"
        chmod 600 "$PRIMARY_KEY_PATH"
        chmod 644 "$PRIMARY_KEY_PATH.pub"

        echo "Key installation complete."
      '')

      # --- transfer_and_install_keys -------------------------------------------
      (pkgs.writeShellScriptBin "transfer_and_install_keys" ''
        #! /usr/bin/env bash
        set -euo pipefail

        if [[ $# -ne 1 ]]; then
          echo "Usage: transfer_and_install_keys <host>" >&2
          exit 1
        fi

        HOST="$1"
        # Use SUDO_USER if running under sudo, otherwise use USER
        REAL_USER="''${SUDO_USER:-$USER}"
        REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

        REMOTE_USER="$REAL_USER@$HOST"
        KEY_PATH="$REAL_HOME/.ssh/id_ed25519"
        LOCAL_INSTALL_KEYS_BIN="$(command -v install_keys || true)"

        [[ -f "$KEY_PATH" ]] || { echo "Missing $KEY_PATH" >&2; exit 1; }
        [[ -n "$LOCAL_INSTALL_KEYS_BIN" ]] || { echo "install_keys not in \$PATH" >&2; exit 1; }

        echo "→ copying SSH key…"
        ssh "$REMOTE_USER" 'mkdir -p ~/.ssh'
        scp "$KEY_PATH" "$REMOTE_USER:~/.ssh/id_ed25519"
        scp "$KEY_PATH".pub "$REMOTE_USER:~/.ssh/id_ed25519.pub"

        echo "→ running install_keys on $HOST…"
        ssh -t "$REMOTE_USER" 'bash install_keys'

        echo "SSH key transferred and install_keys executed successfully on $HOST."
      '')
    ];
}
