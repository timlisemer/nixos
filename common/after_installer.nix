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
  # ─── Restic Backup Configuration ────────────────────────────────────────────────
  services.restic.backups = lib.listToAttrs (builtins.map (path: {
      name = "backup-${hostName}-${lib.replaceStrings ["/"] ["-"] (lib.removePrefix "/" path)}";
      value = {
        initialize = true;
        paths = [path];
        passwordFile = config.sops.secrets.restic_password.path;
        environmentFile = config.sops.secrets.restic_environment.path;
        repositoryFile = config.sops.templates.restic_repo.path;
        pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12"];
        timerConfig.OnCalendar = "06:30";
        timerConfig.Persistent = false;
      };
    })
    backupPaths);

  # Restic helper scripts
  environment.systemPackages = with pkgs;
    lib.mkAfter [
      # Show how much space a given PATH occupies in the repository
      (pkgs.writeShellScriptBin "restic_size" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        echo_info() { echo -e "''${BLUE}''${BOLD}[INFO]''${NC} $1"; }
        echo_success() { echo -e "''${GREEN}''${BOLD}[SUCCESS]''${NC} $1"; }
        echo_error() { echo -e "''${RED}''${BOLD}[ERROR]''${NC} $1" >&2; }

        ENV_FILE="/run/secrets/restic_environment"
        REPO_FILE="/run/secrets/restic_repo_base"
        REPO="$(sudo cat "$REPO_FILE")/$(hostname -s)"

        if [[ $# -ne 1 ]]; then
          echo_error "Usage: restic_size <path>"
          exit 1
        fi
        CHECK="$(sudo realpath "$1")"
        echo_info "Checking size for path: ''${BOLD}$CHECK''${NC}"

        echo_info "Verifying if path exists in snapshots..."
        if ! sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
             restic --repo "$REPO" --password-file /run/secrets/restic_password \
             snapshots --json --path "$CHECK" >/dev/null 2>&1; then
          echo_error "Path '$CHECK' is not present in any snapshot."
          exit 1
        fi
        echo_success "Path found in snapshots."

        echo_info "Calculating size..."
        BYTES=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                 restic --repo "$REPO" --password-file /run/secrets/restic_password \
                 stats latest --mode raw-data --json --path "$CHECK" \
                 | jq '.total_size')
        echo_success "$CHECK: ''${BOLD}$(numfmt --to=iec --suffix=B "$BYTES")''${NC}"
      '')

      # List every unique path stored in the repo together with its size
      (pkgs.writeShellScriptBin "restic_list" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        echo_info() { echo -e "''${BLUE}''${BOLD}[INFO]''${NC} $1"; }
        echo_success() { echo -e "''${GREEN}''${BOLD}[SUCCESS]''${NC} $1"; }
        echo_error() { echo -e "''${RED}''${BOLD}[ERROR]''${NC} $1" >&2; }

        ENV_FILE="/run/secrets/restic_environment"
        REPO_FILE="/run/secrets/restic_repo_base"
        REPO="$(sudo cat "$REPO_FILE")/$(hostname -s)"

        echo_info "Listing all unique paths in the repository..."

        sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
          restic --repo "$REPO" --password-file /run/secrets/restic_password \
          snapshots --json \
          | jq -r '.[] | .paths[]' \
          | sort -u \
          | while read -r p; do
              echo_info "Processing path: ''${BOLD}$p''${NC}"
              restic_size "$p"
            done

        echo_success "Listing complete."
      '')

      # Restore the latest snapshot of PATH into /tmp/restic/partial…
      (pkgs.writeShellScriptBin "restic_restore_to_tmp" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        echo_info() { echo -e "''${BLUE}''${BOLD}[INFO]''${NC} $1"; }
        echo_success() { echo -e "''${GREEN}''${BOLD}[SUCCESS]''${NC} $1"; }
        echo_error() { echo -e "''${RED}''${BOLD}[ERROR]''${NC} $1" >&2; }

        ENV_FILE="/run/secrets/restic_environment"
        REPO_FILE="/run/secrets/restic_repo_base"
        REPO="$(sudo cat "$REPO_FILE")/$(hostname -s)"
        HOST="$(hostname -s)"

        if [[ $# -eq 0 ]]; then
          echo_info "No path argument provided, restoring all paths for ''${BOLD}$HOST''${NC}. Use ''${BOLD}restic_list''${NC} for a full overview of all paths."
          DEST="/tmp/restic/complete"
          echo_info "Preparing destination: ''${BOLD}$DEST''${NC}"
          rm -rf "$DEST"
          mkdir -p "$DEST"

          echo_info "Starting full restore..."
          sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
            restic --repo "$REPO" --password-file /run/secrets/restic_password \
            restore latest --target "$DEST"

          echo_success "Full restore finished at ''${BOLD}$DEST''${NC}"
          exit 0
        elif [[ $# -ne 1 ]]; then
          echo_error "Usage: restic_restore_to_tmp <path>"
          exit 1
        fi

        SRC="$(sudo realpath "$1")"
        echo_info "Restoring path: ''${BOLD}$SRC''${NC}"

        echo_info "Verifying if path exists in snapshots..."
        if ! sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
             restic --repo "$REPO" --password-file /run/secrets/restic_password \
             snapshots --json --path "$SRC" >/dev/null 2>&1; then
          echo_error "Path '$SRC' is not present in any snapshot."
          exit 1
        fi
        echo_success "Path found in snapshots."

        DEST="/tmp/restic/partial"
        echo_info "Preparing destination: ''${BOLD}$DEST''${NC}"
        rm -rf "$DEST"
        mkdir -p "$DEST"

        echo_info "Starting restore..."
        sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
          restic --repo "$REPO" --password-file /run/secrets/restic_password \
          restore latest --path "$SRC" --target "$DEST"

        echo_success "Restore finished at ''${BOLD}$DEST''${NC}"
      '')

      # --- restic_start_backup -------------------------------------------------
      (pkgs.writeShellScriptBin "restic_start_backup" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        echo_info() { echo -e "''${BLUE}''${BOLD}[INFO]''${NC} $1"; }
        echo_success() { echo -e "''${GREEN}''${BOLD}[SUCCESS]''${NC} $1"; }
        echo_error() { echo -e "''${RED}''${BOLD}[ERROR]''${NC} $1" >&2; }

        host="$(hostname -s)"
        unit="restic-backups-''${host}.service"
        echo_info "Starting backup unit: ''${BOLD}$unit''${NC}"

        if sudo systemctl start "$unit"; then
          echo_success "Backup service started successfully."
          echo_info "You can follow the logs with: ''${BOLD}restic_logs''${NC}"
        else
          echo_error "Failed to start backup service."
          exit 1
        fi
      '')

      # --- restic_logs ---------------------------------------------------------
      (pkgs.writeShellScriptBin "restic_logs" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        echo_info() { echo -e "''${BLUE}''${BOLD}[INFO]''${NC} $1"; }
        echo_success() { echo -e "''${GREEN}''${BOLD}[SUCCESS]''${NC} $1"; }
        echo_error() { echo -e "''${RED}''${BOLD}[ERROR]''${NC} $1" >&2; }

        unit="restic-backups-$(hostname -s).service"
        echo_info "Following logs for unit: ''${BOLD}$unit''${NC}"
        echo_info "Showing last 100 lines and following..."

        sudo journalctl -u "$unit" -n 100 --follow
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
        scp "$KEY_PATH".pub "$REMOTE_USER:~/.ssh/id_ed25519.pub"

        echo "→ running install_keys on $HOST…"
        ssh "$REMOTE_USER" 'bash install_keys'

        echo "SSH key transferred and install_keys executed successfully on $HOST."
      '')
    ];
}
