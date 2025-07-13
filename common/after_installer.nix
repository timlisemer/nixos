{
  config,
  pkgs,
  inputs,
  lib,
  backupPaths,
  hostName,
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

  # ─── Restic Backup Configuration ────────────────────────────────────────────────
  services.restic.backups.${hostName} = {
    initialize = true;
    paths = backupPaths;
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.secrets.restic_environment.path;
    repositoryFile = config.sops.templates.restic_repo.path; # hides R2 URL
    pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12"];
    timerConfig.OnCalendar = "06:30";
    timerConfig.Persistent = false; # don't run on boot or rebuild
  };

  # Restic helper scripts
  environment.systemPackages = with pkgs;
    lib.mkAfter [
      # Show how much space a given PATH occupies in the repository
      (pkgs.writeShellScriptBin "restic_size" ''
        #! /usr/bin/env bash
        set -euo pipefail
        if [[ $# -ne 1 ]]; then
          echo "Usage: restic_size <path>" >&2
          exit 1
        fi
        CHECK="$(realpath "$1")"
        if ! restic snapshots --json --path "$CHECK" >/dev/null 2>&1; then
          echo "Path '$CHECK' is not present in any snapshot." >&2
          exit 1
        fi
        BYTES=$(restic stats latest --mode raw-data --json --path "$CHECK" | jq '.total_size')
        echo "$CHECK: $(numfmt --to=iec --suffix=B "$BYTES")"
      '')

      # List every unique path stored in the repo together with its size
      (pkgs.writeShellScriptBin "restic_list" ''
        #! /usr/bin/env bash
        set -euo pipefail
        restic snapshots --json \
          | jq -r '.[] | .paths[]' \
          | sort -u \
          | while read -r p; do
              restic_size "$p"
            done
      '')

      # Restore the latest snapshot of PATH into /tmp/restic…
      (pkgs.writeShellScriptBin "restic_restore_to_tmp" ''
        #! /usr/bin/env bash
        set -euo pipefail
        if [[ $# -ne 1 ]]; then
          echo "Usage: restic_restore_to_tmp <path>" >&2
          exit 1
        fi
        SRC="$(realpath "$1")"
        if ! restic snapshots --json --path "$SRC" >/dev/null 2>&1; then
          echo "Path '$SRC' is not present in any snapshot." >&2
          exit 1
        fi
        DEST="/tmp/restic$SRC"
        echo "Restoring to $DEST"
        rm -rf "$DEST"
        mkdir -p "$DEST"
        restic restore latest --path "$SRC" --target "$DEST"
        echo "Restore finished at $DEST"
      '')

      # --- restic_start_backup -------------------------------------------------
      (pkgs.writeShellScriptBin "restic_start_backup" ''
        #! /usr/bin/env bash
        set -euo pipefail
        host="$(hostname -s)"
        unit="restic-backups-${host}.service"
        echo "Starting backup unit: $unit"
        sudo systemctl start "$unit"
      '')

      # --- restic_logs ---------------------------------------------------------
      (pkgs.writeShellScriptBin "restic_logs" ''
        #! /usr/bin/env bash
        set -euo pipefail
        unit="restic-backups-$(hostname -s).service"
        journalctl -u "$unit" -n 100 --follow
      '')

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
        REMOTE_USER="$USER@$HOST"
        KEY_PATH="$HOME/.ssh/id_ed25519"
        LOCAL_INSTALL_KEYS_BIN="$(command -v install_keys || true)"

        [[ -f "$KEY_PATH"          ]] || { echo "Missing $KEY_PATH" >&2; exit 1; }
        [[ -n "$LOCAL_INSTALL_KEYS_BIN" ]] || { echo "install_keys not in \$PATH" >&2; exit 1; }

        echo "→ copying SSH key…"
        ssh "$REMOTE_USER" 'mkdir -p ~/.ssh'
        scp "$KEY_PATH" "$REMOTE_USER:~/.ssh/id_ed25519"

        echo "→ running install_keys on $HOST…"
        ssh "$REMOTE_USER" 'bash install_keys'

        echo "SSH key transferred and install_keys executed successfully on $HOST."
      '')
    ];
}
