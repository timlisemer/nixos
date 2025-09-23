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
  # Single systemd service that runs the restic_start_backup function
  systemd.services.restic-backup = {
    description = "Restic backup service";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      EnvironmentFile = config.sops.secrets.restic_environment.path;
    };
    script = "restic_start_backup";
    path = with pkgs; [restic jq coreutils] ++ config.environment.systemPackages;
  };

  systemd.timers.restic-backup = {
    description = "Timer for restic backup service";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "06:30";
      Persistent = false;
    };
  };

  # Make backup paths available as a file
  environment.etc."restic_predefined_backup_paths.json".text = builtins.toJSON backupPaths;

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

        # Check for direct snapshots first
        if env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
             restic --repo "$REPO" --password-file "$PWD_FILE" \
             snapshots --json --path "$NATIVE_PATH" >/dev/null 2>&1; then
          echo_success "Path found in direct snapshots."

          echo_info "Calculating size..."
          BYTES=$(env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                   restic --repo "$REPO" --password-file "$PWD_FILE" \
                   stats latest --mode raw-data --json --path "$NATIVE_PATH" 2>/dev/null \
                   | jq '.total_size' 2>/dev/null || echo "0")
          echo_success "$NATIVE_PATH: ''${BOLD}$(numfmt --to=iec --suffix=B "$BYTES")''${NC}"
        else
          echo_info "No direct snapshots found, checking for nested repositories..."

          # Extract S3 variables from REPO_BASE for nested repository detection
          S3_ENDPOINT=$(echo "$REPO_BASE" | sed -n 's|s3:\(https://[^/]*\)/.*|\1|p')
          S3_BUCKET=$(echo "$REPO_BASE" | sed -n 's|s3:https://[^/]*/\(.*\)|\1|p')

          # Check for nested repositories (filter out restic internal structure)
          nested_dirs=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
            aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/''${SUBPATH}/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | \
            grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' || echo "")

          # Filter out restic internal structure (data, index, keys, snapshots)
          nested_repos=""
          if [[ -n "$nested_dirs" ]]; then
            for dir in $nested_dirs; do
              if [[ "$dir" != "data" && "$dir" != "index" && "$dir" != "keys" && "$dir" != "snapshots" ]]; then
                nested_repos+="$dir "
              fi
            done
            nested_repos=$(echo "$nested_repos" | sed 's/[[:space:]]*$//')  # trim trailing spaces
          fi

          if [[ -n "$nested_repos" ]]; then
            echo_info "Found REAL nested repositories: $nested_repos"

            TOTAL_BYTES=0
            found_any=false

            for nested_repo in $nested_repos; do
              if [[ -n "$nested_repo" ]]; then
                nested_repo_url="s3://''${S3_BUCKET}/''${HOST}/''${SUBPATH}/''${nested_repo}"
                nested_native_path="''${NATIVE_PATH}/''${nested_repo}"

                echo_info "  Checking size for $nested_native_path..."

                # Check if nested repository has snapshots for this path
                if sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                   restic --repo "$nested_repo_url" --password-file "$PWD_FILE" \
                   snapshots --json --path "$nested_native_path" >/dev/null 2>&1; then

                  nested_bytes=$(env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                                 restic --repo "$nested_repo_url" --password-file "$PWD_FILE" \
                                 stats latest --mode raw-data --json --path "$nested_native_path" 2>/dev/null \
                                 | jq '.total_size' 2>/dev/null || echo "0")

                  if [[ "$nested_bytes" != "0" ]]; then
                    echo_success "    $nested_native_path: $(numfmt --to=iec --suffix=B "$nested_bytes")"
                    TOTAL_BYTES=$((TOTAL_BYTES + nested_bytes))
                    found_any=true
                  fi
                else
                  echo_info "    No snapshots found for $nested_native_path"
                fi
              fi
            done

            if [[ "$found_any" == "true" ]]; then
              echo_success "''${BOLD}Total size for $NATIVE_PATH (all nested repositories): $(numfmt --to=iec --suffix=B "$TOTAL_BYTES")''${NC}"
            else
              echo_error "No snapshots found in any nested repositories for '$NATIVE_PATH'."
              exit 1
            fi
          elif [[ -n "$nested_dirs" ]]; then
            echo_info "Found restic internal structure (data/index/keys/snapshots) - not nested repos"
            echo_error "Path '$NATIVE_PATH' is not present in any snapshot and no real nested repositories found."
            exit 1
          else
            echo_error "Path '$NATIVE_PATH' is not present in any snapshot and no nested repositories found."
            exit 1
          fi
        fi
      '')

      # --- restic_start_backup -------------------------------------------------
      (pkgs.writeShellScriptBin "restic_start_backup" ''
        #! /usr/bin/env bash
        set -uo pipefail

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

        host="$(hostname -s)"
        echo_info "Starting backup process for host: ''${BOLD}$host''${NC}"

        # Read secrets paths
        ENV_FILE="/run/secrets/restic_environment"
        REPO_BASE_FILE="/run/secrets/restic_repo_base"
        REPO_BASE="$(sudo cat "$REPO_BASE_FILE")"
        PWD_FILE="/run/secrets/restic_password"

        # Export AWS credentials for restic
        export $(sudo grep -v '^#' "$ENV_FILE" | xargs)

        backup_count=0

        # Backup user paths from file
        if [[ -f "/etc/restic_predefined_backup_paths.json" ]]; then
          echo_info "Processing configured backup paths..."
          while read -r path; do
            if [[ -n "$path" ]]; then
              # Check if path exists, skip if not but don't fail
              if [[ ! -e "$path" ]]; then
                echo_warning "Path does not exist, skipping: $path"
                continue
              fi

              echo_info "Backing up: $path"

              # Calculate repository location - with error handling
              repo_location=""
              if [[ "$path" =~ ^/home/ ]]; then
                username=$(echo "$path" | cut -d/ -f3)
                subdir=$(echo "$path" | cut -d/ -f4- | tr '/' '_')
                if [[ -n "$subdir" ]]; then
                  repo_location="user_home/$username/$subdir"
                else
                  repo_location="user_home/$username"
                fi
              elif [[ "$path" =~ ^/mnt/docker-data/volumes/ ]]; then
                volume=$(echo "$path" | cut -d/ -f5- | tr '/' '_')
                repo_location="docker_volume/$volume"
              else
                repo_location="system"
              fi

              if [[ -z "$repo_location" ]]; then
                echo_warning "Could not determine repository location for: $path"
                continue
              fi

              repo_url="$REPO_BASE/$host/$repo_location"

              # Initialize repository if needed - with proper error handling
              init_success=false
              if sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                   restic --repo "$repo_url" --password-file "$PWD_FILE" snapshots >/dev/null 2>&1; then
                init_success=true
              elif sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                   restic --repo "$repo_url" --password-file "$PWD_FILE" init >/dev/null 2>&1; then
                init_success=true
              fi

              # Only proceed with backup if repository is ready
              if [[ "$init_success" == "true" ]]; then
                # Capture restic output to determine success/partial success/failure
                backup_output=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                    restic --repo "$repo_url" --password-file "$PWD_FILE" backup "$path" \
                    --host "$host" \
                    --tag user-path 2>&1)
                backup_exit_code=$?

                # Check if snapshot was created (indicates success or partial success)
                if echo "$backup_output" | grep -q "snapshot .* saved"; then
                  snapshot_id=$(echo "$backup_output" | grep "snapshot .* saved" | awk '{print $2}')

                  # Check for warnings about unreadable files
                  if echo "$backup_output" | grep -q "at least one source file could not be read"; then
                    failed_files=$(echo "$backup_output" | grep -c "failed to save\|input/output error" || echo "0")
                    echo_warning "Backed up: $path (snapshot $snapshot_id) - $failed_files files skipped due to I/O errors"
                  else
                    echo_success "Backed up: $path (snapshot $snapshot_id)"
                  fi
                  ((backup_count++))
                else
                  # True failure - no snapshot created
                  echo_error_lines=$(echo "$backup_output" | head -3)
                  echo_warning "Failed to backup: $path"
                  echo_warning "Error: $echo_error_lines"
                fi
              else
                echo_warning "Failed to initialize repository for: $path"
              fi
            fi
          done < <(sudo cat /etc/restic_predefined_backup_paths.json | jq -r '.[]')
        fi

        # Backup docker volumes
        if [[ -d "/mnt/docker-data/volumes" ]]; then
          echo_info "Processing docker volumes..."
          for volume_path in /mnt/docker-data/volumes/*/; do
            if [[ -d "$volume_path" ]]; then
              volume_name=$(basename "$volume_path")
              # Exclude non-volume entries
              if [[ "$volume_name" == "backingFsBlockDev" || "$volume_name" == "metadata.db" ]]; then
                continue
              fi

              echo_info "Backing up docker volume: $volume_name"
              repo_url="$REPO_BASE/$host/docker_volume/$volume_name"

              # Initialize repository if needed - with proper error handling
              init_success=false
              if sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                   restic --repo "$repo_url" --password-file "$PWD_FILE" snapshots >/dev/null 2>&1; then
                init_success=true
              elif sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                   restic --repo "$repo_url" --password-file "$PWD_FILE" init >/dev/null 2>&1; then
                init_success=true
              fi

              # Only proceed with backup if repository is ready
              if [[ "$init_success" == "true" ]]; then
                # Capture restic output to determine success/partial success/failure
                backup_output=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                    restic --repo "$repo_url" --password-file "$PWD_FILE" backup "$volume_path" \
                    --host "$host" \
                    --tag docker-volume \
                    --tag "$volume_name" 2>&1)
                backup_exit_code=$?

                # Check if snapshot was created (indicates success or partial success)
                if echo "$backup_output" | grep -q "snapshot .* saved"; then
                  snapshot_id=$(echo "$backup_output" | grep "snapshot .* saved" | awk '{print $2}')

                  # Check for warnings about unreadable files
                  if echo "$backup_output" | grep -q "at least one source file could not be read"; then
                    failed_files=$(echo "$backup_output" | grep -c "failed to save\|input/output error" || echo "0")
                    echo_warning "Backed up docker volume: $volume_name (snapshot $snapshot_id) - $failed_files files skipped due to I/O errors"
                  else
                    echo_success "Backed up docker volume: $volume_name (snapshot $snapshot_id)"
                  fi
                  ((backup_count++))
                else
                  # True failure - no snapshot created
                  echo_error_lines=$(echo "$backup_output" | head -3)
                  echo_warning "Failed to backup docker volume: $volume_name"
                  echo_warning "Error: $echo_error_lines"
                fi
              else
                echo_warning "Failed to initialize repository for docker volume: $volume_name"
              fi
            fi
          done
        fi

        echo_info "Backup completed: $backup_count successful"
        echo_info "You can check logs with: ''${BOLD}sudo journalctl -u restic-backup -f''${NC}"

        # Ensure successful exit
        exit 0
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
        aws s3 ls "s3://$S3_BUCKET/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' || true
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
          users=$(aws s3 ls "s3://$S3_BUCKET/$host/user_home/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' || true)
          if [[ -n "$users" ]]; then
            for user in $users; do
              echo >&2 "[INFO] Processing user: $user"
              aws s3 ls "s3://$S3_BUCKET/$host/user_home/$user/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' | while IFS= read -r subdir; do
                [[ -n "$subdir" ]] || continue
                echo >&2 "[INFO]   Checking $subdir..."
                local snapshots
                if snapshots=$(env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                  restic --repo "$REPO_BASE/$host/user_home/$user/$subdir" --password-file "$PWD_FILE" \
                  snapshots --json 2>/dev/null); then
                  echo "$snapshots" | jq -r --arg path "/home/$user/$subdir" '.[] | "\(.time)|\($path)|\(.short_id)"' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
                fi
              done
            done
          fi

          echo >&2 "[INFO] Scanning docker volumes..."
          # Docker Volumes
          aws s3 ls "s3://$S3_BUCKET/$host/docker_volume/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' | while IFS= read -r volume; do
            [[ -n "$volume" ]] || continue
            echo >&2 "[INFO] Processing volume: $volume"
            local snapshots

            # Try direct repository first
            if snapshots=$(env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
              restic --repo "$REPO_BASE/$host/docker_volume/$volume" --password-file "$PWD_FILE" \
              snapshots --json 2>/dev/null); then
              echo "$snapshots" | jq -r --arg path "/mnt/docker-data/volumes/$volume" '.[] | "\(.time)|\($path)|\(.short_id)"' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
            else
              # Check for nested repositories (filter out restic internal structure)
              echo >&2 "[INFO]   No direct snapshots found for $volume, checking nested repositories..."
              nested_dirs=$(aws s3 ls "s3://$S3_BUCKET/$host/docker_volume/$volume/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' || true)

              # Filter out restic internal structure (data, index, keys, snapshots)
              nested_repos=""
              if [[ -n "$nested_dirs" ]]; then
                for dir in $nested_dirs; do
                  if [[ "$dir" != "data" && "$dir" != "index" && "$dir" != "keys" && "$dir" != "snapshots" ]]; then
                    nested_repos+="$dir "
                  fi
                done
                nested_repos=$(echo "$nested_repos" | sed 's/[[:space:]]*$//')  # trim trailing spaces
              fi

              if [[ -n "$nested_repos" ]]; then
                echo >&2 "[INFO]   Found REAL nested repositories in $volume: $nested_repos"
                for nested_repo in $nested_repos; do
                    echo >&2 "[INFO]     Processing nested: $volume/$nested_repo"
                    if snapshots=$(env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                      restic --repo "$REPO_BASE/$host/docker_volume/$volume/$nested_repo" --password-file "$PWD_FILE" \
                      snapshots --json 2>/dev/null); then
                      echo "$snapshots" | jq -r --arg path "/mnt/docker-data/volumes/$volume/$nested_repo" '.[] | "\(.time)|\($path)|\(.short_id)"' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
                    fi
                  done
                elif [[ -n "$nested_dirs" ]]; then
                  echo >&2 "[INFO]   Found restic internal structure in $volume (data/index/keys/snapshots) - not nested repos"
                else
                  echo >&2 "[INFO]   No nested repositories found for $volume"
                fi
              fi
            done

          echo >&2 "[INFO] Scanning system paths..."
          # System
          aws s3 ls "s3://$S3_BUCKET/$host/system/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' | while IFS= read -r path; do
            [[ -n "$path" ]] || continue
            echo >&2 "[INFO] Processing system: $path"
            local snapshots
            if snapshots=$(env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
              restic --repo "$REPO_BASE/$host/system/$path" --password-file "$PWD_FILE" \
              snapshots --json 2>/dev/null); then
              echo "$snapshots" | jq -r --arg path "/$path" '.[] | "\(.time)|\($path)|\(.short_id)"' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
            fi
          done

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

          # If no direct snapshots found, check for nested repositories (for docker volumes)
          if [[ "$count" -eq 0 ]] && [[ "$repo_path" =~ ^docker_volume/ ]]; then
            progress_info "  No direct snapshots for $native_path, checking nested repositories..."

            # Extract volume name from repo_path (docker_volume/volume_name)
            local volume_name=$(echo "$repo_path" | sed 's|^docker_volume/||')

            # Check for nested repositories (filter out restic internal structure)
            local nested_dirs=$(aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/docker_volume/''${volume_name}/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' || true)

            # Filter out restic internal structure (data, index, keys, snapshots)
            local nested_repos=""
            if [[ -n "$nested_dirs" ]]; then
              for dir in $nested_dirs; do
                if [[ "$dir" != "data" && "$dir" != "index" && "$dir" != "keys" && "$dir" != "snapshots" ]]; then
                  nested_repos+="$dir "
                fi
              done
              nested_repos=$(echo "$nested_repos" | sed 's/[[:space:]]*$//')  # trim trailing spaces
            fi

            if [[ -n "$nested_repos" ]]; then
              progress_info "  Found REAL nested repositories in $volume_name: $nested_repos"

              # Collect snapshots from each REAL nested repository
              for nested_repo in $nested_repos; do
                if [[ -n "$nested_repo" ]]; then
                  local nested_repo_path="docker_volume/$volume_name/$nested_repo"
                  local nested_native_path="$native_path/$nested_repo"

                  progress_info "    Processing nested: $nested_repo"

                  # Get snapshots for nested repository
                  local nested_snapshots
                  if nested_snapshots=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                    restic --repo "$REPO_BASE/$HOST/$nested_repo_path" --password-file "$PWD_FILE" \
                    snapshots --json 2>/dev/null); then

                    local nested_count=0
                    if [[ -n "$nested_snapshots" ]] && [[ "$nested_snapshots" != "[]" ]]; then
                      nested_count=$(echo "$nested_snapshots" | jq 'length' 2>/dev/null || echo "0")
                    fi

                    if [[ "$nested_count" -gt 0 ]]; then
                      echo "$nested_native_path|$nested_count" >> "$PATHS_FILE"
                      echo "$nested_snapshots" | jq -r --arg path "$nested_native_path" '.[] | "\(.time)|\($path)|\(.short_id)"' >> "$SNAPSHOTS_FILE" 2>/dev/null || true
                      count=$((count + nested_count))
                    fi
                  fi
                fi
              done
              # Don't record the parent path if we found REAL nested repositories
              return
            elif [[ -n "$nested_dirs" ]]; then
              progress_info "  Found restic internal structure in $volume_name (data/index/keys/snapshots) - not nested repos"
            fi
          fi

          # Only record the path if it has direct snapshots or no nested repos were found
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
        users=$(aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/user_home/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' || true)
        if [[ -n "$users" ]]; then
          for user in $users; do
            progress_info "Processing user: $user"
            aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/user_home/''${user}/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' | while IFS= read -r subdir; do
              [[ -n "$subdir" ]] || continue
              progress_info "  Checking $subdir..."
              collect_snapshots "user_home/$user/$subdir" "/home/$user/$subdir"
            done
          done
        fi

        progress_info "Scanning docker volumes..."
        # Collect Docker Volumes
        aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/docker_volume/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' | while IFS= read -r volume; do
          [[ -n "$volume" ]] || continue
          progress_info "Processing volume: $volume"
          collect_snapshots "docker_volume/$volume" "/mnt/docker-data/volumes/$volume"
        done

        progress_info "Scanning system paths..."
        # Collect System
        aws s3 ls "s3://''${S3_BUCKET}/''${HOST}/system/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' | while IFS= read -r path; do
          [[ -n "$path" ]] || continue
          progress_info "Processing system: $path"
          collect_snapshots "system/$path" "/$path"
        done

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
            # Keep the nested structure for docker volumes (don't convert slashes to underscores)
            volume=$(echo "$path" | cut -d/ -f5-)
            echo "docker_volume/$volume"
          else
            # system paths
            echo "system"
          fi
        }

        # Build selected repositories array
        selected_repos_array=()
        case "$restore_choice" in
          1)
            # All repositories
            while IFS='|' read -r path count; do
              if [[ -n "$path" ]]; then
                repo_subpath=$(path_to_repo_subpath "$path")
                selected_repos_array+=("$repo_subpath")
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
                selected_repos_array+=("$repo_subpath")
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
                selected_repos_array+=("$repo_subpath")
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
                selected_repos_array+=("$repo_subpath")
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

            # Build selected repos array
            for idx in "''${selected_indices[@]}"; do
              IFS='|' read -r repo_subpath native_path snapshot_count <<< "''${repo_array[$idx]}"
              selected_repos_array+=("$repo_subpath")
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
            selected_repos_array=("$repo_subpath")
            echo_info "Selected: $native_path"
            ;;
          *)
            echo_error "Invalid choice"
            exit 1
            ;;
        esac

        if [[ ''${#selected_repos_array[*]} -eq 0 ]]; then
          echo_error "No repositories selected"
          exit 1
        fi

        # Show what will be restored
        repo_count=''${#selected_repos_array[*]}
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
        for repo_subpath in "''${selected_repos_array[@]}"; do
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
        done

        # Group timestamps into 5-minute windows
        GROUP_TIMESTAMPS=$(mktemp)
        GROUP_COUNTS=$(mktemp)
        trap "rm -f $BACKUP_PATHS_FILE $BACKUP_SNAPSHOTS_FILE $FILTERED_TIMESTAMPS $GROUP_TIMESTAMPS $GROUP_COUNTS" EXIT

        # Process timestamps and group by 5-minute windows
        while IFS= read -r timestamp; do
          if [[ -n "$timestamp" ]]; then
            # Convert ISO timestamp to epoch for grouping
            epoch=$(date -d "$timestamp" +%s 2>/dev/null || echo "0")
            if [[ "$epoch" != "0" ]]; then
              # Round down to 5-minute boundary (300 seconds)
              group_epoch=$((epoch - (epoch % 300)))
              group_timestamp=$(date -d "@$group_epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown")
              echo "$group_timestamp|$timestamp" >> "$GROUP_TIMESTAMPS"
            fi
          fi
        done < <(sort -u -r "$FILTERED_TIMESTAMPS")

        if [[ ! -s "$GROUP_TIMESTAMPS" ]]; then
          echo_error "No snapshots found for selected repositories"
          exit 1
        fi

        # Count snapshots per group and create display array
        group_array=()
        while IFS= read -r group_time; do
          count=$(grep -c "^$group_time|" "$GROUP_TIMESTAMPS" 2>/dev/null || echo "0")
          group_array+=("$group_time|$count")
        done < <(cut -d'|' -f1 "$GROUP_TIMESTAMPS" | sort -u -r)

        echo "Available restore time windows (5-minute groups):"
        for i in "''${!group_array[@]}"; do
          IFS='|' read -r group_time count <<< "''${group_array[$i]}"
          # Format: "1. 2025-08-23 06:30-06:35 (17 snapshots)"
          end_time=$(date -d "$group_time +5 minutes" '+%H:%M' 2>/dev/null || echo "??:??")
          start_time=$(date -d "$group_time" '+%H:%M' 2>/dev/null || echo "??:??")
          date_part=$(date -d "$group_time" '+%Y-%m-%d' 2>/dev/null || echo "unknown")
          echo "  $((i + 1)). $date_part $start_time-$end_time ($count snapshots)"
        done

        echo
        read -p "Select time window [1]: " timestamp_choice
        timestamp_choice=''${timestamp_choice:-1}

        if [[ ! "$timestamp_choice" =~ ^[0-9]+$ ]] || [[ "$timestamp_choice" -lt 1 ]] || [[ "$timestamp_choice" -gt ''${#group_array[@]} ]]; then
          echo_error "Invalid time window selection"
          exit 1
        fi

        IFS='|' read -r SELECTED_GROUP count <<< "''${group_array[$((timestamp_choice - 1))]}"
        echo_info "Selected time window: ''${BOLD}$SELECTED_GROUP (+5 minutes)''${NC}"
        echo

        # Phase 5: Restoration
        DEST="/tmp/restic/interactive"
        echo_info "Preparing destination: ''${BOLD}$DEST''${NC}"

        # Check if destination exists and is not empty
        if [[ -d "$DEST" ]] && [[ -n "$(sudo find "$DEST" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
          echo_warning "Destination directory is not empty:"
          sudo ls -la "$DEST" 2>/dev/null | head -10
          echo
          echo "This will delete all existing files in $DEST"
          read -p "Continue and clear the directory? (y/N): " clear_confirm
          if [[ ! "$clear_confirm" =~ ^[Yy]$ ]]; then
            echo_error "Operation cancelled by user"
            exit 1
          fi
        fi

        sudo rm -rf "$DEST"
        sudo mkdir -p "$DEST"

        echo_info "Starting restoration process..."
        restored_count=0
        skipped_count=0

        for repo_subpath in "''${selected_repos_array[@]}"; do
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

            # Get all snapshots for this repository
            snapshots=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
              restic --repo "$REPO" --password-file "$PWD_FILE" \
              snapshots --json --path "$native_path" 2>/dev/null || echo "[]")

            if [[ "$snapshots" == "[]" ]] || [[ $(echo "$snapshots" | jq 'length') -eq 0 ]]; then
              echo_info "No direct snapshots found for $native_path, checking for nested repositories..."

              # Extract S3 variables from REPO_BASE for nested repository detection
              S3_ENDPOINT=$(echo "$REPO_BASE" | sed -n 's|s3:\(https://[^/]*\)/.*|\1|p')
              S3_BUCKET=$(echo "$REPO_BASE" | sed -n 's|s3:https://[^/]*/\(.*\)|\1|p')

              # Check for nested repositories (filter out restic internal structure)
              nested_dirs=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                aws s3 ls "s3://''${S3_BUCKET}/''${SELECTED_HOST}/''${repo_subpath}/" --endpoint-url "$S3_ENDPOINT" 2>/dev/null | \
                grep "PRE" | sed 's/.*PRE //' | sed 's|/$||' || echo "")

              # Filter out restic internal structure (data, index, keys, snapshots)
              nested_repos=""
              if [[ -n "$nested_dirs" ]]; then
                for dir in $nested_dirs; do
                  if [[ "$dir" != "data" && "$dir" != "index" && "$dir" != "keys" && "$dir" != "snapshots" ]]; then
                    nested_repos+="$dir "
                  fi
                done
                nested_repos=$(echo "$nested_repos" | sed 's/[[:space:]]*$//')  # trim trailing spaces
              fi

              if [[ -n "$nested_repos" ]]; then
                echo_info "Found REAL nested repositories: $nested_repos"
              elif [[ -n "$nested_dirs" ]]; then
                echo_info "Found restic internal structure (data/index/keys/snapshots) - not nested repos"
              fi

              if [[ -n "$nested_repos" ]]; then
                nested_restored=0
                nested_skipped=0

                # Process each REAL nested repository
                for nested_repo in $nested_repos; do
                  if [[ -n "$nested_repo" ]]; then
                    nested_repo_subpath="$repo_subpath/$nested_repo"
                    nested_native_path="$native_path/$nested_repo"
                    nested_repo_url="s3://''${S3_BUCKET}/''${SELECTED_HOST}/''${nested_repo_subpath}"

                    echo_info "  Restoring ''${BOLD}$nested_native_path''${NC} from ''${BOLD}$nested_repo_subpath''${NC}..."

                    # Get snapshots for the nested repository
                    nested_snapshots=$(sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                      restic --repo "$nested_repo_url" --password-file "$PWD_FILE" \
                      snapshots --json --path "$nested_native_path" 2>/dev/null || echo "[]")

                    if [[ "$nested_snapshots" == "[]" ]] || [[ $(echo "$nested_snapshots" | jq 'length') -eq 0 ]]; then
                      echo_warning "  No snapshots found for $nested_native_path, skipping"
                      nested_skipped=$((nested_skipped + 1))
                      continue
                    fi

                    # Find best snapshot within the time window
                    best_nested_snapshot=$(echo "$nested_snapshots" | jq -r --arg group_start "$(date -d "@$group_start_epoch" '+%Y-%m-%dT%H:%M:%S')" \
                      --arg group_end "$(date -d "@$group_end_epoch" '+%Y-%m-%dT%H:%M:%S')" '
                      ([.[] | select(.time >= $group_start and .time <= $group_end)] | sort_by(.time) | last) as $in_window |
                      ([.[] | select(.time < $group_start)] | sort_by(.time) | last) as $before_window |
                      (($in_window // $before_window) | .short_id // empty)'
                    )

                    if [[ -n "$best_nested_snapshot" ]] && [[ "$best_nested_snapshot" != "null" ]]; then
                      # Get timestamp for logging
                      nested_snapshot_time=$(echo "$nested_snapshots" | jq -r --arg snapshot_id "$best_nested_snapshot" '
                        .[] | select(.short_id == $snapshot_id) | .time'
                      )

                      # Restore the nested snapshot
                      sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
                        restic --repo "$nested_repo_url" --password-file "$PWD_FILE" \
                        restore "$best_nested_snapshot" --path "$nested_native_path" --target "$DEST"

                      # Check if restoration created files or directories in the target directory
                      nested_restored_files=$(sudo find "$DEST" -path "*$nested_native_path*" -type f 2>/dev/null | wc -l)
                      nested_restored_dirs=$(sudo find "$DEST" -path "*$nested_native_path*" -type d 2>/dev/null | wc -l)
                      nested_restored_items=$((nested_restored_files + nested_restored_dirs))

                      if [[ $nested_restored_items -gt 0 ]]; then
                        display_time=$(echo "$nested_snapshot_time" | sed 's/\.[0-9]*+.*$//')
                        if [[ $nested_restored_files -gt 0 ]]; then
                          echo_success "  Restored $nested_native_path from snapshot $best_nested_snapshot at $display_time ($nested_restored_files files, $nested_restored_dirs dirs)"
                        else
                          echo_success "  Restored $nested_native_path from snapshot $best_nested_snapshot at $display_time (empty volume - $nested_restored_dirs dirs only)"
                        fi
                        nested_restored=$((nested_restored + 1))
                      else
                        echo_error "  Failed to restore $nested_native_path - no files or directories found in destination"
                        nested_skipped=$((nested_skipped + 1))
                      fi
                    else
                      echo_warning "  No suitable snapshots found for $nested_native_path, skipping"
                      nested_skipped=$((nested_skipped + 1))
                    fi
                  fi
                done

                # Update overall counters
                restored_count=$((restored_count + nested_restored))
                skipped_count=$((skipped_count + nested_skipped))

                if [[ $nested_restored -gt 0 ]]; then
                  echo_success "Successfully restored $nested_restored nested repositories from $repo_subpath"
                else
                  echo_warning "No nested repositories could be restored from $repo_subpath"
                fi
                continue
              else
                echo_warning "No snapshots found for $native_path and no REAL nested repositories detected, skipping"
                skipped_count=$((skipped_count + 1))
                continue
              fi
            fi

            # Calculate time window boundaries
            group_start_epoch=$(date -d "$SELECTED_GROUP" +%s 2>/dev/null || echo "0")
            group_end_epoch=$((group_start_epoch + 300))  # +5 minutes

            # Find best snapshot within the time window, or the newest before the window
            best_snapshot=$(echo "$snapshots" | jq -r --arg group_start "$(date -d "@$group_start_epoch" '+%Y-%m-%dT%H:%M:%S')" \
              --arg group_end "$(date -d "@$group_end_epoch" '+%Y-%m-%dT%H:%M:%S')" '
              # Try to find snapshots within the time window first
              ([.[] | select(.time >= $group_start and .time <= $group_end)] | sort_by(.time) | last) as $in_window |
              # If none in window, find the newest snapshot before the window
              ([.[] | select(.time < $group_start)] | sort_by(.time) | last) as $before_window |
              # Use in-window snapshot if available, otherwise use before-window snapshot
              (($in_window // $before_window) | .short_id // empty)'
            )

            # Get the timestamp of the selected snapshot for logging
            selected_snapshot_time=$(echo "$snapshots" | jq -r --arg snapshot_id "$best_snapshot" '
              .[] | select(.short_id == $snapshot_id) | .time'
            )

            if [[ -z "$best_snapshot" ]] || [[ "$best_snapshot" == "null" ]]; then
              echo_warning "No suitable snapshots found for $native_path, skipping"
              skipped_count=$((skipped_count + 1))
              continue
            fi

            # Restore the selected snapshot
            sudo env $(sudo grep -v '^#' "$ENV_FILE" | xargs) \
              restic --repo "$REPO" --password-file "$PWD_FILE" \
              restore "$best_snapshot" --path "$native_path" --target "$DEST"

            # Check if restoration created files or directories in the target directory
            restored_files=$(sudo find "$DEST" -path "*$native_path*" -type f 2>/dev/null | wc -l)
            restored_dirs=$(sudo find "$DEST" -path "*$native_path*" -type d 2>/dev/null | wc -l)
            restored_items=$((restored_files + restored_dirs))

            if [[ $restored_items -gt 0 ]]; then
              # Format timestamp for display (remove microseconds and timezone for readability)
              display_time=$(echo "$selected_snapshot_time" | sed 's/\.[0-9]*+.*$//')
              if [[ $restored_files -gt 0 ]]; then
                echo_success "Restored $native_path from snapshot $best_snapshot at $display_time ($restored_files files, $restored_dirs dirs)"
              else
                echo_success "Restored $native_path from snapshot $best_snapshot at $display_time (empty volume - $restored_dirs dirs only)"
              fi
              restored_count=$((restored_count + 1))
            else
              echo_error "Failed to restore $native_path - no files or directories found in destination"
              skipped_count=$((skipped_count + 1))
            fi
          fi
        done

        echo
        echo_info "Restoration Summary:"
        echo "  Successfully restored: $restored_count repositories"
        echo "  Skipped: $skipped_count repositories"
        echo "  Destination: ''${BOLD}$DEST''${NC}"

        if [[ $restored_count -gt 0 ]]; then
          echo_success "Restoration completed successfully!"
          echo_info "You can now access your restored files at $DEST"
          echo

          # Offer to move or copy files to original location
          echo "What would you like to do with the restored files?"
          echo "  1. Copy to original location (replace existing files)"
          echo "  2. Move to original location (replace existing files)"
          echo "  3. Leave files in temporary location"
          echo
          read -p "Your choice [3]: " final_action
          final_action=''${final_action:-3}

          case "$final_action" in
            1)
              echo_info "Copying files to original locations..."
              copy_success=true
              for repo_subpath in "''${selected_repos_array[@]}"; do
                if [[ -n "$repo_subpath" ]]; then
                  # Find the native path for this repo
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

                  if [[ -n "$native_path" ]]; then
                    echo_info "Copying $native_path..."
                    # Create parent directory
                    if ! sudo mkdir -p "$(dirname "$native_path")"; then
                      echo_error "Failed to create parent directory $(dirname "$native_path")"
                      copy_success=false
                      continue
                    fi
                    # Just copy it (cp -rf will overwrite)
                    if ! sudo cp -rf "$DEST$native_path" "$(dirname "$native_path")"; then
                      echo_error "Failed to copy $native_path"
                      echo_error "Source: $DEST$native_path"
                      echo_error "Target: $(dirname "$native_path")"
                      copy_success=false
                    else
                      echo_success "Copied $native_path"
                    fi
                  fi
                fi
              done

              if [[ "$copy_success" == "true" ]]; then
                echo_success "All files copied successfully to their original locations"
                echo_info "Temporary files remain at $DEST"
              else
                echo_warning "Some files failed to copy. Check the logs above for details."
              fi
              ;;

            2)
              echo_info "Moving files to original locations...."
              echo_info "DEBUG: selected_repos_array contains: ''${selected_repos_array[*]}"
              echo_info "DEBUG: DEST is: $DEST"
              echo_info "DEBUG: Contents of $DEST:"
              sudo find "$DEST" -maxdepth 3 -type d

              move_success=true
              for repo_subpath in "''${selected_repos_array[@]}"; do
                echo_info "DEBUG: Processing repo_subpath: $repo_subpath"
                if [[ -n "$repo_subpath" ]]; then
                  # Find the native path for this repo
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

                  echo_info "DEBUG: native_path found: $native_path"
                  echo_info "DEBUG: Checking if $DEST$native_path exists..."

                  if [[ -n "$native_path" ]]; then
                    echo_info "Moving $native_path..."
                    # Remove original if it exists (for replace)
                    if [[ -e "$native_path" ]]; then
                      if ! sudo rm -rf "$native_path"; then
                        echo_error "Failed to remove existing $native_path"
                        move_success=false
                        continue
                      fi
                    fi
                    # Create parent directory
                    if ! sudo mkdir -p "$(dirname "$native_path")"; then
                      echo_error "Failed to create parent directory $(dirname "$native_path")"
                      move_success=false
                      continue
                    fi
                    # Move contents, not the directory itself
                    if [[ -d "$DEST$native_path" ]] && sudo mv "$DEST$native_path"/* "$native_path" 2>/dev/null; then
                      echo_success "Moved $native_path contents"
                    else
                      # Fallback: move the whole directory
                      if ! sudo mv "$DEST$native_path" "$(dirname "$native_path")/"; then
                        echo_error "Failed to move $native_path"
                        echo_error "Source: $DEST$native_path"
                        echo_error "Target: $native_path"
                        move_success=false
                      else
                        echo_success "Moved $native_path"
                      fi
                    fi
                  fi
                else
                  echo_warning "DEBUG: repo_subpath was empty, skipping"
                fi
              done

              if [[ "$move_success" == "true" ]]; then
                echo_success "All files moved successfully to their original locations"
                echo_info "Cleaning up temporary directory..."
                sudo rm -rf "$DEST" 2>/dev/null || true
              else
                echo_warning "Some files failed to move. Check the logs above for details."
                echo_info "Temporary files remain at $DEST"
              fi
              ;;

            3|*)
              echo_info "Files remain at temporary location: $DEST"
              echo_info "You can manually copy or move them as needed"
              ;;
          esac
        else
          echo_warning "No files were restored. Check the logs above for details."
        fi
      '')
    ];
}
