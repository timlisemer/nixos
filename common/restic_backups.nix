# restic_backups.nix
{
  config,
  pkgs,
  lib,
  backupPaths,
  hostName,
  ...
}: let
  getLocation = path: let
    cleanParts = lib.filter (x: x != "") (lib.splitString "/" path);
  in
    if (lib.hasPrefix "/home/" path) && (builtins.length cleanParts >= 2) && (builtins.elemAt cleanParts 0 == "home")
    then let
      username = builtins.elemAt cleanParts 1;
      subParts = lib.drop 2 cleanParts;
      subPathStr =
        if subParts == []
        then ""
        else "/" + lib.concatStringsSep "_" subParts;
    in
      "user_home/" + username + subPathStr
    else if (lib.hasPrefix "/mnt/docker-data/volumes/" path) && (builtins.length cleanParts >= 4) && (builtins.elemAt cleanParts 0 == "mnt") && (builtins.elemAt cleanParts 1 == "docker-data") && (builtins.elemAt cleanParts 2 == "volumes")
    then "docker_volume/" + (lib.concatStringsSep "_" (lib.drop 3 cleanParts))
    else "system";
in {
  # ─── Restic Backup Configuration ────────────────────────────────────────────────
  sops.templates = lib.listToAttrs (builtins.map (path: let
      location = getLocation path;
      name = "backup-${hostName}-${lib.replaceStrings ["/"] ["-"] (lib.removePrefix "/" path)}";
    in {
      name = "restic_repo_${name}";
      value = {
        owner = "root";
        mode = "0400";
        content = "${config.sops.placeholder."restic_repo_base"}/${hostName}/${location}";
        restartUnits = ["restic-backups-${name}.service"];
      };
    })
    backupPaths);
  services.restic.backups = lib.listToAttrs (builtins.map (path: let
      location = getLocation path;
      name = "backup-${hostName}-${lib.replaceStrings ["/"] ["-"] (lib.removePrefix "/" path)}";
    in {
      name = name;
      value = {
        initialize = true;
        paths = [path];
        passwordFile = config.sops.secrets.restic_password.path;
        environmentFile = config.sops.secrets.restic_environment.path;
        repositoryFile = config.sops.templates."restic_repo_${name}".path;
        pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12"];
        timerConfig.OnCalendar = "06:30";
        timerConfig.Persistent = false;
      };
    })
    backupPaths);
  # Generate JSON for backup paths
  environment.etc."restic_backup_paths.json".text = builtins.toJSON (builtins.map (path: {
      native_path = path;
      repo_subpath = getLocation path;
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
        REPO_BASE_FILE="/run/secrets/restic_repo_base"
        REPO_BASE="$(sudo cat "$REPO_BASE_FILE")"
        HOST="$(hostname -s)"
        PWD_FILE="/run/secrets/restic_password"
        PATHS_FILE="/etc/restic_backup_paths.json"

        if [[ $# -ne 1 ]]; then
          echo_error "Usage: restic_size <native_path>"
          exit 1
        fi
        NATIVE_PATH="$(sudo realpath "$1")"
        echo_info "Checking size for path: ''${BOLD}$NATIVE_PATH''${NC}"

        # Find the repo subpath for the native path
        SUBPATH=$(sudo jq -r --arg p "$NATIVE_PATH" '.[] | select(.native_path == $p) | .repo_subpath' "$PATHS_FILE")
        if [[ -z "$SUBPATH" ]]; then
          echo_error "No backup repository found for path '$NATIVE_PATH'."
          exit 1
        fi

        REPO="$REPO_BASE/$HOST/$SUBPATH"

        echo_info "Verifying if path exists in snapshots..."
        if ! sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
             restic --repo "$REPO" --password-file "$PWD_FILE" \
             snapshots --json --path "$NATIVE_PATH" >/dev/null 2>&1; then
          echo_error "Path '$NATIVE_PATH' is not present in any snapshot in repo '$REPO'."
          exit 1
        fi
        echo_success "Path found in snapshots."

        echo_info "Calculating size..."
        BYTES=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                 restic --repo "$REPO" --password-file "$PWD_FILE" \
                 stats latest --mode raw-data --json --path "$NATIVE_PATH" 2>/dev/null \
                 | jq '.total_size' 2>/dev/null || echo "0")
        echo_success "$NATIVE_PATH: ''${BOLD}$(numfmt --to=iec --suffix=B "$BYTES")''${NC}"
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
        echo_info "Starting all backup units for host: ''${BOLD}$host''${NC}"

        units=$(sudo systemctl list-unit-files --type=service --plain | grep "^restic-backups-backup-$host-" | awk '{print $1}')
        if [[ -z "$units" ]]; then
          echo_error "No backup units found."
          exit 1
        fi

        for unit in $units; do
          echo_info "Starting ''${BOLD}$unit''${NC}"
          if sudo systemctl start "$unit"; then
            echo_success "$unit started successfully."
          else
            echo_error "Failed to start $unit."
          fi
        done

        echo_info "You can follow the logs with: ''${BOLD}restic_logs''${NC}"
      '')

      # --- Helper Functions ---------------------------------------------------

      # Get all available hostnames from S3 bucket
      (pkgs.writeShellScriptBin "restic_get_hosts" ''
        #! /usr/bin/env bash
        set -euo pipefail

        ENV_FILE="/run/secrets/restic_environment"
        REPO_BASE_FILE="/run/secrets/restic_repo_base"
        REPO_BASE="$(sudo cat "$REPO_BASE_FILE")"

        # Export AWS credentials
        export $(sudo grep -v '^#' "$ENV_FILE" | xargs)

        # Extract S3 endpoint and bucket
        S3_ENDPOINT=$(echo "$REPO_BASE" | sed -n 's|s3:\(https://[^/]*\)/.*|\1|p')
        S3_BUCKET=$(echo "$REPO_BASE" | sed -n 's|s3:https://[^/]*/\(.*\)|\1|p')

        # List all available hosts
        aws s3 ls "s3://$S3_BUCKET/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true
      '')

      # Get snapshot timeline data for a specific host
      (pkgs.writeShellScriptBin "restic_get_timeline" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        if [[ $# -ne 1 ]]; then
          echo "Usage: restic_get_timeline <hostname>"
          exit 1
        fi

        HOST="$1"
        ENV_FILE="/run/secrets/restic_environment"
        REPO_BASE_FILE="/run/secrets/restic_repo_base"
        REPO_BASE="$(sudo cat "$REPO_BASE_FILE")"
        PWD_FILE="/run/secrets/restic_password"

        # Export AWS credentials
        export $(sudo grep -v '^#' "$ENV_FILE" | xargs)

        # Extract S3 endpoint and bucket
        S3_ENDPOINT=$(echo "$REPO_BASE" | sed -n 's|s3:\(https://[^/]*\)/.*|\1|p')
        S3_BUCKET=$(echo "$REPO_BASE" | sed -n 's|s3:https://[^/]*/\(.*\)|\1|p')

        # Temporary file for snapshots
        SNAPSHOTS_FILE=$(mktemp)
        trap "rm -f $SNAPSHOTS_FILE" EXIT

        # Collect snapshots from all repositories for this host
        collect_host_snapshots() {
          local host="$1"

          echo >&2 "[INFO] Scanning user home directories..."
          # User Home
          users=$(aws s3 ls "s3://$S3_BUCKET/$host/user_home/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true)
          if [[ -n "$users" ]]; then
            for user in $users; do
              echo >&2 "[INFO] Processing user: $user"
              subdirs=$(aws s3 ls "s3://$S3_BUCKET/$host/user_home/$user/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true)
              for subdir in $subdirs; do
                echo >&2 "[INFO]   Checking $subdir..."
                local snapshots
                if snapshots=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                  restic --repo "$REPO_BASE/$host/user_home/$user/$subdir" --password-file "$PWD_FILE" \
                  snapshots --json 2>/dev/null); then
                  echo "$snapshots" | jq -r '.[] | .time' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
                fi
              done
            done
          fi

          echo >&2 "[INFO] Scanning docker volumes..."
          # Docker Volumes
          volumes=$(aws s3 ls "s3://$S3_BUCKET/$host/docker_volume/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true)
          if [[ -n "$volumes" ]]; then
            for volume in $volumes; do
              echo >&2 "[INFO] Processing volume: $volume"
              local snapshots
              if snapshots=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                restic --repo "$REPO_BASE/$host/docker_volume/$volume" --password-file "$PWD_FILE" \
                snapshots --json 2>/dev/null); then
                echo "$snapshots" | jq -r '.[] | .time' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
              fi
            done
          fi

          echo >&2 "[INFO] Scanning system paths..."
          # System
          system_paths=$(aws s3 ls "s3://$S3_BUCKET/$host/system/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true)
          if [[ -n "$system_paths" ]]; then
            for path in $system_paths; do
              echo >&2 "[INFO] Processing system: $path"
              local snapshots
              if snapshots=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                restic --repo "$REPO_BASE/$host/system/$path" --password-file "$PWD_FILE" \
                snapshots --json 2>/dev/null); then
                echo "$snapshots" | jq -r '.[] | .time' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
              fi
            done
          fi

          echo >&2 "[INFO] Scanning completed!"
        }

        collect_host_snapshots "$HOST"

        # Output unique timestamps sorted in reverse chronological order, grouped by minute
        if [[ -s "$SNAPSHOTS_FILE" ]]; then
          sort -ru "$SNAPSHOTS_FILE" | awk '{
            timestamp = substr($1, 1, 16)  # Get YYYY-MM-DDTHH:MM
            if (timestamp != last_timestamp) {
              date_part = substr($1, 1, 10)
              time_part = substr($1, 12, 8)
              print date_part " " time_part
              last_timestamp = timestamp
            }
          }'
        fi
      '')

      # --- restic_list ---------------------------------------------
      (pkgs.writeShellScriptBin "restic_list" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        # Support both display and return modes
        RETURN_MODE=false
        TARGET_HOST=""
        if [[ $# -gt 0 ]] && [[ "$1" == "--return" ]]; then
          RETURN_MODE=true
          if [[ $# -gt 1 ]]; then
            TARGET_HOST="$2"
          fi
        elif [[ $# -gt 0 ]] && [[ "$1" != "--return" ]]; then
          TARGET_HOST="$1"
        fi

        ENV_FILE="/run/secrets/restic_environment"
        REPO_BASE_FILE="/run/secrets/restic_repo_base"
        REPO_BASE="$(sudo cat "$REPO_BASE_FILE")"
        HOST="''${TARGET_HOST:-$(hostname -s)}"
        PWD_FILE="/run/secrets/restic_password"

        # Export AWS credentials
        export $(sudo grep -v '^#' "$ENV_FILE" | xargs)

        # Extract S3 endpoint and bucket
        S3_ENDPOINT=$(echo "$REPO_BASE" | sed -n 's|s3:\(https://[^/]*\)/.*|\1|p')
        S3_BUCKET=$(echo "$REPO_BASE" | sed -n 's|s3:https://[^/]*/\(.*\)|\1|p')

        if [[ "$RETURN_MODE" == "false" ]]; then
          echo "Listing backups for $HOST from S3 bucket..."
          echo
        fi

        # Temporary files for collecting data
        PATHS_FILE=$(mktemp)
        SNAPSHOTS_FILE=$(mktemp)
        trap "rm -f $PATHS_FILE $SNAPSHOTS_FILE" EXIT

        # Collect all paths and their snapshots
        collect_snapshots() {
          local repo_path="$1"
          local native_path="$2"

          # Get snapshots for this repo - with proper error handling
          local snapshots
          if ! snapshots=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
            restic --repo "$REPO_BASE/$HOST/$repo_path" --password-file "$PWD_FILE" \
            snapshots --json 2>/dev/null); then
            snapshots="[]"
          fi

          # Safe JSON parsing
          local count=0
          if [[ -n "$snapshots" ]] && [[ "$snapshots" != "[]" ]]; then
            count=$(echo "$snapshots" | jq 'length' 2>/dev/null || echo "0")
          fi

          echo "$native_path|$count" >> "$PATHS_FILE"

          if [[ "$count" -gt 0 ]] && [[ "$snapshots" != "[]" ]]; then
            echo "$snapshots" | jq -r --arg path "$native_path" '.[] | "\(.time)|\($path)|\(.short_id)"' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
          fi
        }

        # Progress function - output to stderr in return mode, stdout in display mode
        if [[ "$RETURN_MODE" == "false" ]]; then
          progress_info() { echo -e "''${BLUE}''${BOLD}[INFO]''${NC} $1"; }
        else
          progress_info() { echo >&2 -e "''${BLUE}''${BOLD}[INFO]''${NC} $1"; }
        fi

        progress_info "Scanning user home directories..."
        # Collect User Home
        users=$(aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/user_home/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true)
        if [[ -n "$users" ]]; then
          for user in $users; do
            progress_info "Processing user: $user"
            subdirs=$(aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/user_home/''${user}/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true)
            for subdir in $subdirs; do
              progress_info "  Checking $subdir..."
              collect_snapshots "user_home/''${user}/''${subdir}" "/home/''${user}/''${subdir}"
            done
          done
        fi

        progress_info "Scanning docker volumes..."
        # Collect Docker Volumes
        volumes=$(aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/docker_volume/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true)
        if [[ -n "$volumes" ]]; then
          for volume in $volumes; do
            progress_info "Processing volume: $volume"
            collect_snapshots "docker_volume/''${volume}" "/mnt/docker-data/volumes/''${volume}"
          done
        fi

        progress_info "Scanning system paths..."
        # Collect System
        system_paths=$(aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/system/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | awk '{print $2}' | sed 's|/$||' || true)
        if [[ -n "$system_paths" ]]; then
          for path in $system_paths; do
            progress_info "Processing system: $path"
            collect_snapshots "system/''${path}" "/''${path}"
          done
        fi

        progress_info "Scanning completed!"

        if [[ "$RETURN_MODE" == "true" ]]; then
          # Simple JSON output - just return the raw data files as base64 for parsing elsewhere
          echo "{"
          echo "  \"host\": \"$HOST\","
          echo "  \"paths_data\": \"$(base64 -w 0 "$PATHS_FILE" 2>/dev/null || echo "")\","
          echo "  \"snapshots_data\": \"$(base64 -w 0 "$SNAPSHOTS_FILE" 2>/dev/null || echo "")\""
          echo "}"
        else
          # Display formatted output (existing behavior)
          echo "BACKUP PATHS SUMMARY:"
          echo "===================="

          # User Home summary
          user_paths=$(grep "^/home/" "$PATHS_FILE" 2>/dev/null || true)
          user_count=$(echo "$user_paths" | grep -c "^" 2>/dev/null || echo "0")
          echo "User Home ($user_count paths):"
          if [[ -n "$user_paths" ]]; then
            echo "$user_paths" | while IFS='|' read -r path count; do
              printf "  %-40s - %s snapshots\n" "$path" "$count"
            done | sort
          else
            echo "  None"
          fi
          echo

          # Docker Volumes summary
          docker_paths=$(grep "^/mnt/docker-data/" "$PATHS_FILE" 2>/dev/null || true)
          docker_count=$(echo "$docker_paths" | grep -c "^" 2>/dev/null || echo "0")
          echo "Docker Volumes ($docker_count paths):"
          if [[ -n "$docker_paths" ]]; then
            echo "$docker_paths" | while IFS='|' read -r path count; do
              printf "  %-40s - %s snapshots\n" "$path" "$count"
            done | sort
          else
            echo "  None"
          fi
          echo

          # System summary
          system_paths=$(grep -v "^/home/" "$PATHS_FILE" 2>/dev/null | grep -v "^/mnt/docker-data/" 2>/dev/null || true)
          system_count=$(echo "$system_paths" | grep -c "^" 2>/dev/null || echo "0")
          echo "System ($system_count paths):"
          if [[ -n "$system_paths" ]]; then
            echo "$system_paths" | while IFS='|' read -r path count; do
              printf "  %-40s - %s snapshots\n" "$path" "$count"
            done | sort
          else
            echo "  None"
          fi
          echo

          # Display timeline
          echo "SNAPSHOT TIMELINE:"
          echo "=================="

          if [[ -s "$SNAPSHOTS_FILE" ]]; then
            # Group snapshots by timestamp (within 1 minute)
            sort -r "$SNAPSHOTS_FILE" | awk -F'|' '
            {
              timestamp = substr($1, 1, 16)  # Get YYYY-MM-DDTHH:MM
              if (timestamp != last_timestamp) {
                if (NR > 1) print ""
                # Format the timestamp nicely
                date_part = substr($1, 1, 10)
                time_part = substr($1, 12, 8)
                print date_part " " time_part ":"
                last_timestamp = timestamp
              }
              printf "  - %-40s (id: %s)\n", $2, $3
            }'
          else
            echo "No snapshots found"
          fi
          echo
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

        host="$(hostname -s)"
        echo_info "Following logs for all restic backup units on ''${BOLD}$host''${NC}"
        echo_info "Showing last 100 lines and following..."

        sudo journalctl -u "restic-backups-backup-$host-*" -n 100 --follow
      '')

      # --- restic_restore ------------------------------------------------------
      (pkgs.writeShellScriptBin "restic_restore" ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Color definitions
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        YELLOW='\033[1;33m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        echo_info() { echo -e "''${BLUE}''${BOLD}[INFO]''${NC} $1"; }
        echo_success() { echo -e "''${GREEN}''${BOLD}[SUCCESS]''${NC} $1"; }
        echo_error() { echo -e "''${RED}''${BOLD}[ERROR]''${NC} $1" >&2; }
        echo_warning() { echo -e "''${YELLOW}''${BOLD}[WARNING]''${NC} $1"; }

        ENV_FILE="/run/secrets/restic_environment"
        REPO_BASE_FILE="/run/secrets/restic_repo_base"
        REPO_BASE="$(sudo cat "$REPO_BASE_FILE")"
        CURRENT_HOST="$(hostname -s)"
        PWD_FILE="/run/secrets/restic_password"

        echo_info "Restic Interactive Restore Tool"
        echo "==============================="
        echo

        # Phase 1: Hostname Selection
        echo_info "Getting available hostnames..."
        available_hosts=$(restic_get_hosts)
        if [[ -z "$available_hosts" ]]; then
          echo_error "No hosts found in backup repository"
          exit 1
        fi

        echo
        echo "Available hosts:"
        host_array=($available_hosts)
        default_index=0

        # Find current host in list for default
        for i in "''${!host_array[@]}"; do
          if [[ "''${host_array[$i]}" == "$CURRENT_HOST" ]]; then
            default_index=$((i + 1))
          fi
          echo "  $((i + 1)). ''${host_array[$i]}"
        done

        echo
        read -p "Select hostname [$default_index]: " host_choice
        host_choice=''${host_choice:-$default_index}

        if [[ ! "$host_choice" =~ ^[0-9]+$ ]] || [[ "$host_choice" -lt 1 ]] || [[ "$host_choice" -gt ''${#host_array[@]} ]]; then
          echo_error "Invalid selection"
          exit 1
        fi

        SELECTED_HOST="''${host_array[$((host_choice - 1))]}"
        echo_info "Selected host: ''${BOLD}$SELECTED_HOST''${NC}"
        echo

        # Phase 2: Get backup data for selected host
        echo_info "Querying backups for $SELECTED_HOST..."
        backup_json=$(restic_list --return "$SELECTED_HOST")

        if [[ -z "$backup_json" ]] || [[ "$backup_json" == "{}" ]]; then
          echo_error "No backup data found for host $SELECTED_HOST"
          exit 1
        fi

        # Extract and decode the data
        paths_data_b64=$(echo "$backup_json" | jq -r '.paths_data // ""')
        snapshots_data_b64=$(echo "$backup_json" | jq -r '.snapshots_data // ""')

        # Create temporary files with the decoded data
        BACKUP_PATHS_FILE=$(mktemp)
        BACKUP_SNAPSHOTS_FILE=$(mktemp)
        trap "rm -f $BACKUP_PATHS_FILE $BACKUP_SNAPSHOTS_FILE" EXIT

        if [[ -n "$paths_data_b64" ]] && [[ "$paths_data_b64" != "null" ]]; then
          echo "$paths_data_b64" | base64 -d > "$BACKUP_PATHS_FILE" 2>/dev/null || true
        fi

        if [[ -n "$snapshots_data_b64" ]] && [[ "$snapshots_data_b64" != "null" ]]; then
          echo "$snapshots_data_b64" | base64 -d > "$BACKUP_SNAPSHOTS_FILE" 2>/dev/null || true
        fi

        # Parse available categories
        user_home_count=0
        docker_count=0
        system_count=0

        if [[ -s "$BACKUP_PATHS_FILE" ]]; then
          while IFS='|' read -r path count; do
            if [[ -n "$path" ]]; then
              if [[ "$path" =~ ^/home/ ]]; then
                user_home_count=$((user_home_count + 1))
              elif [[ "$path" =~ ^/mnt/docker-data/ ]]; then
                docker_count=$((docker_count + 1))
              else
                system_count=$((system_count + 1))
              fi
            fi
          done < "$BACKUP_PATHS_FILE"
        fi

        echo_success "Found backups: User Home ($user_home_count), Docker Volumes ($docker_count), System ($system_count)"
        echo

        # Phase 3: Repository Selection
        echo "Select what to restore:"
        echo "  1. All (everything for $SELECTED_HOST)"
        if [[ "$user_home_count" -gt 0 ]]; then
          echo "  2. User Home (all user directories)"
        else
          echo -e "  \033[2m2. User Home (all user directories) - no backups available\033[0m"
        fi
        if [[ "$docker_count" -gt 0 ]]; then
          echo "  3. Docker Volumes (all docker volumes)"
        else
          echo -e "  \033[2m3. Docker Volumes (all docker volumes) - no backups available\033[0m"
        fi
        if [[ "$system_count" -gt 0 ]]; then
          echo "  4. System (all system paths)"
        else
          echo -e "  \033[2m4. System (all system paths) - no backups available\033[0m"
        fi
        echo "  5. Custom Selection (choose specific repositories)"
        echo "  6. Individual Repository (easy single-repo selection)"
        echo

        read -p "Your choice: " restore_choice

        # Helper function to convert path to repo subpath
        path_to_repo_subpath() {
          local path="$1"
          if [[ "$path" =~ ^/home/ ]]; then
            # user_home/tim/.config -> user_home/tim/.config
            user=$(echo "$path" | cut -d/ -f3)
            subdir=$(echo "$path" | cut -d/ -f4-)
            if [[ -n "$subdir" ]]; then
              # Replace slashes with underscores in subdir
              subdir_escaped=$(echo "$subdir" | tr '/' '_')
              echo "user_home/$user/$subdir_escaped"
            else
              echo "user_home/$user"
            fi
          elif [[ "$path" =~ ^/mnt/docker-data/volumes/ ]]; then
            # docker_volume/volume_name with slashes converted to underscores
            volume=$(echo "$path" | cut -d/ -f5-)
            volume_escaped=$(echo "$volume" | tr '/' '_')
            echo "docker_volume/$volume_escaped"
          else
            # system paths
            echo "system"
          fi
        }

        # Build selected repositories list
        selected_repos=""
        case "$restore_choice" in
          1)
            # All repositories
            while IFS='|' read -r path count; do
              if [[ -n "$path" ]]; then
                repo_subpath=$(path_to_repo_subpath "$path")
                selected_repos+="$repo_subpath"$'\n'
              fi
            done < "$BACKUP_PATHS_FILE"
            ;;
          2)
            # User Home only
            if [[ "$user_home_count" -eq 0 ]]; then
              echo_error "No user home backups available"
              exit 1
            fi
            while IFS='|' read -r path count; do
              if [[ "$path" =~ ^/home/ ]]; then
                repo_subpath=$(path_to_repo_subpath "$path")
                selected_repos+="$repo_subpath"$'\n'
              fi
            done < "$BACKUP_PATHS_FILE"
            ;;
          3)
            # Docker Volumes only
            if [[ "$docker_count" -eq 0 ]]; then
              echo_error "No docker volume backups available"
              exit 1
            fi
            while IFS='|' read -r path count; do
              if [[ "$path" =~ ^/mnt/docker-data/ ]]; then
                repo_subpath=$(path_to_repo_subpath "$path")
                selected_repos+="$repo_subpath"$'\n'
              fi
            done < "$BACKUP_PATHS_FILE"
            ;;
          4)
            # System only
            if [[ "$system_count" -eq 0 ]]; then
              echo_error "No system backups available"
              exit 1
            fi
            while IFS='|' read -r path count; do
              if [[ ! "$path" =~ ^/home/ ]] && [[ ! "$path" =~ ^/mnt/docker-data/ ]]; then
                repo_subpath=$(path_to_repo_subpath "$path")
                selected_repos+="$repo_subpath"$'\n'
              fi
            done < "$BACKUP_PATHS_FILE"
            ;;
          5)
            # Custom selection - interactive multi-select
            echo_info "Available repositories:"

            repo_array=()
            while IFS='|' read -r path count; do
              if [[ -n "$path" ]]; then
                repo_subpath=$(path_to_repo_subpath "$path")
                repo_array+=("$repo_subpath|$path|$count")
              fi
            done < "$BACKUP_PATHS_FILE"

            if [[ ''${#repo_array[@]} -eq 0 ]]; then
              echo_error "No repositories found"
              exit 1
            fi

            # Display repositories with numbers
            for i in "''${!repo_array[@]}"; do
              IFS='|' read -r repo_subpath native_path snapshot_count <<< "''${repo_array[$i]}"
              printf "%3d. %-40s (%d snapshots)\n" $((i + 1)) "$native_path" "$snapshot_count"
            done

            echo
            echo "Enter repository numbers separated by spaces (e.g., 1 3 5-8):"
            read -p "Selection: " custom_selection

            # Parse selection (support ranges like 1-3)
            selected_indices=()
            for part in $custom_selection; do
              if [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
                # Range format
                start=$(echo "$part" | cut -d- -f1)
                end=$(echo "$part" | cut -d- -f2)
                for ((i=start; i<=end; i++)); do
                  if [[ $i -ge 1 ]] && [[ $i -le ''${#repo_array[@]} ]]; then
                    selected_indices+=($((i - 1)))
                  fi
                done
              elif [[ "$part" =~ ^[0-9]+$ ]]; then
                # Single number
                if [[ $part -ge 1 ]] && [[ $part -le ''${#repo_array[@]} ]]; then
                  selected_indices+=($((part - 1)))
                fi
              fi
            done

            if [[ ''${#selected_indices[@]} -eq 0 ]]; then
              echo_error "No valid selections made"
              exit 1
            fi

            # Build selected repos list
            selected_repos=""
            for idx in "''${selected_indices[@]}"; do
              IFS='|' read -r repo_subpath native_path snapshot_count <<< "''${repo_array[$idx]}"
              selected_repos+="$repo_subpath"$'\n'
            done
            ;;
          6)
            # Individual Repository - easy single selection
            echo_info "Available repositories (select just one):"

            repo_array=()
            while IFS='|' read -r path count; do
              if [[ -n "$path" ]]; then
                repo_subpath=$(path_to_repo_subpath "$path")
                repo_array+=("$repo_subpath|$path|$count")
              fi
            done < "$BACKUP_PATHS_FILE"

            if [[ ''${#repo_array[@]} -eq 0 ]]; then
              echo_error "No repositories found"
              exit 1
            fi

            # Display repositories with numbers - more compact format
            for i in "''${!repo_array[@]}"; do
              IFS='|' read -r repo_subpath native_path snapshot_count <<< "''${repo_array[$i]}"
              printf "%3d. %s (%d snapshots)\n" $((i + 1)) "$native_path" "$snapshot_count"
            done

            echo
            read -p "Select repository number: " single_choice

            if [[ ! "$single_choice" =~ ^[0-9]+$ ]] || [[ "$single_choice" -lt 1 ]] || [[ "$single_choice" -gt ''${#repo_array[@]} ]]; then
              echo_error "Invalid selection"
              exit 1
            fi

            # Get the selected repository
            IFS='|' read -r repo_subpath native_path snapshot_count <<< "''${repo_array[$((single_choice - 1))]}"
            selected_repos="$repo_subpath"
            echo_info "Selected: $native_path"
            ;;
          *)
            echo_error "Invalid choice"
            exit 1
            ;;
        esac

        if [[ -z "$selected_repos" ]]; then
          echo_error "No repositories selected"
          exit 1
        fi

        # Show what will be restored
        repo_count=$(echo "$selected_repos" | grep -v '^$' | wc -l)
        echo_info "Selected $repo_count repositories for restoration"
        echo

        # Phase 4: Timestamp Selection - extract from cached data for selected repositories
        echo_info "Getting available timestamps..."

        # Extract unique timestamps from cached snapshot data, filtered by selected repositories
        if [[ ! -s "$BACKUP_SNAPSHOTS_FILE" ]]; then
          echo_error "No snapshot data available"
          exit 1
        fi

        # Create a temporary file with only timestamps for selected repositories
        FILTERED_TIMESTAMPS=$(mktemp)
        trap "rm -f $BACKUP_PATHS_FILE $BACKUP_SNAPSHOTS_FILE $FILTERED_TIMESTAMPS" EXIT

        # For each selected repository, find matching native paths and extract their timestamps
        while IFS= read -r repo_subpath; do
          if [[ -n "$repo_subpath" ]]; then
            # Find the native path for this repo
            while IFS='|' read -r path count; do
              if [[ -n "$path" ]]; then
                test_repo_subpath=$(path_to_repo_subpath "$path")
                if [[ "$test_repo_subpath" == "$repo_subpath" ]]; then
                  # Extract timestamps for this specific path
                  grep "^[^|]*|$path|" "$BACKUP_SNAPSHOTS_FILE" | cut -d'|' -f1 >> "$FILTERED_TIMESTAMPS" || true
                  break
                fi
              fi
            done < "$BACKUP_PATHS_FILE"
          fi
        done <<< "$selected_repos"

        timestamps=$(sort -u -r "$FILTERED_TIMESTAMPS")
        if [[ -z "$timestamps" ]]; then
          echo_error "No snapshots found for selected repositories"
          exit 1
        fi

        echo "Available restore points:"
        timestamp_array=()
        while IFS= read -r line; do
          if [[ -n "$line" ]]; then
            timestamp_array+=("$line")
          fi
        done <<< "$timestamps"

        for i in "''${!timestamp_array[@]}"; do
          echo "  $((i + 1)). ''${timestamp_array[$i]}"
        done

        echo
        read -p "Select timestamp [1]: " timestamp_choice
        timestamp_choice=''${timestamp_choice:-1}

        if [[ ! "$timestamp_choice" =~ ^[0-9]+$ ]] || [[ "$timestamp_choice" -lt 1 ]] || [[ "$timestamp_choice" -gt ''${#timestamp_array[@]} ]]; then
          echo_error "Invalid timestamp selection"
          exit 1
        fi

        SELECTED_TIMESTAMP="''${timestamp_array[$((timestamp_choice - 1))]}"
        echo_info "Selected timestamp: ''${BOLD}$SELECTED_TIMESTAMP''${NC}"
        echo

        # Phase 5: Restoration
        DEST="/tmp/restic/interactive"
        echo_info "Preparing destination: ''${BOLD}$DEST''${NC}"
        sudo rm -rf "$DEST"
        sudo mkdir -p "$DEST"

        echo_info "Starting restoration process..."
        restored_count=0
        skipped_count=0

        while IFS= read -r repo_subpath; do
          if [[ -n "$repo_subpath" ]]; then
            REPO="$REPO_BASE/$SELECTED_HOST/$repo_subpath"

            # Get native path from backup data
            native_path=""
            while IFS='|' read -r path count; do
              if [[ -n "$path" ]]; then
                test_repo_subpath=$(path_to_repo_subpath "$path")
                if [[ "$test_repo_subpath" == "$repo_subpath" ]]; then
                  native_path="$path"
                  break
                fi
              fi
            done < "$BACKUP_PATHS_FILE"

            echo_info "Restoring ''${BOLD}$native_path''${NC} from ''${BOLD}$repo_subpath''${NC}..."

            # Find closest snapshot <= selected timestamp
            snapshots=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
              restic --repo "$REPO" --password-file "$PWD_FILE" \
              snapshots --json --path "$native_path" 2>/dev/null || echo "[]")

            if [[ "$snapshots" == "[]" ]] || [[ $(echo "$snapshots" | jq 'length') -eq 0 ]]; then
              echo_warning "No snapshots found for $native_path, skipping"
              skipped_count=$((skipped_count + 1))
              continue
            fi

            # Find best snapshot (closest to but not after selected timestamp)
            selected_timestamp_iso="''${SELECTED_TIMESTAMP:0:10}T''${SELECTED_TIMESTAMP:11:8}"
            best_snapshot=$(echo "$snapshots" | jq -r --arg target "$selected_timestamp_iso" '
              [.[] | select(.time <= $target)] |
              sort_by(.time) |
              last // empty |
              .short_id'
            )

            if [[ -z "$best_snapshot" ]] || [[ "$best_snapshot" == "null" ]]; then
              echo_warning "No snapshots found before or at $SELECTED_TIMESTAMP for $native_path, skipping"
              skipped_count=$((skipped_count + 1))
              continue
            fi

            # Restore the selected snapshot
            if sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
              restic --repo "$REPO" --password-file "$PWD_FILE" \
              restore "$best_snapshot" --path "$native_path" --target "$DEST" 2>/dev/null; then
              echo_success "Restored $native_path (snapshot: $best_snapshot)"
              restored_count=$((restored_count + 1))
            else
              echo_error "Failed to restore $native_path"
              skipped_count=$((skipped_count + 1))
            fi
          fi
        done <<< "$selected_repos"

        echo
        echo_info "Restoration Summary:"
        echo "  Successfully restored: $restored_count repositories"
        echo "  Skipped: $skipped_count repositories"
        echo "  Destination: ''${BOLD}$DEST''${NC}"

        if [[ $restored_count -gt 0 ]]; then
          echo_success "Restoration completed successfully!"
          echo_info "You can now access your restored files at $DEST"
        else
          echo_warning "No files were restored. Check the logs above for details."
        fi
      '')
    ];
}
