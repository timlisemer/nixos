{
  config,
  pkgs,
  inputs,
  home-manager,
  lib,
  users,
  hostName,
  hostIps,
  ...
}: let
  dockerBin = "${pkgs.docker}/bin/docker";
  mcpToolboxImage =
    if pkgs.stdenv.hostPlatform.system == "aarch64-linux"
    then "ghcr.io/timlisemer/mcp-toolbox/mcp-toolbox-linux-arm64:latest"
    else "ghcr.io/timlisemer/mcp-toolbox/mcp-toolbox-linux-amd64:latest";
  unstable = import inputs.nixpkgs-unstable {
    config = {allowUnfree = true;};
    system = pkgs.stdenv.hostPlatform.system;
  };
in {
  nixpkgs.overlays = [inputs.rust-overlay.overlays.default];

  # imports
  imports = [
    home-manager.nixosModules.home-manager
  ];

  nix.settings = {
    # do **not** use mkForce – let other modules add their entries
    substituters = [
      "file:///nix/store?trusted=1" # keep local store
      "https://cache.nixos.org?priority=40"
      "https://nixos-raspberrypi.cachix.org?priority=30"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];

    trusted-users = ["root" "@wheel"];
  };

  # Environment Variables
  environment.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    MOZ_DISABLE_RDD_SANDBOX = "1";
    MUTTER_DEBUG_KMS_THREAD_TYPE = "user";
    NODE_OPTIONS = "--max-old-space-size=4096";
    SGX_ENCLAVE_SIZE = "4G";
    RUST_MIN_STACK = "268435456";
    QT_QPA_PLATFORM = "wayland";
    # ESP32-H2 (riscv32imac-unknown-none-elf) tooling
    CARGO_TARGET_RISCV32IMAC_UNKNOWN_NONE_ELF_LINKER = "${pkgs.llvmPackages_latest.lld}/bin/ld.lld";
    LDPROXY_LINKER = "${pkgs.llvmPackages_latest.lld}/bin/ld.lld";
    CARGO_TARGET_RISCV32IMAC_UNKNOWN_NONE_ELF_RUNNER = "${pkgs.espflash}/bin/espflash flash --monitor";
    ESPFLASH_BAUD = "921600";
    # WEBKIT_DISABLE_DMABUF_RENDERER = "1"; # Tauri Apps couldn’t run on NixOS NVIDIA
    # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig:${pkgs.gtk3.dev}/lib/pkgconfig:${pkgs.gtk4.dev}/lib/pkgconfig";
    BLESH_PATH = "${pkgs.blesh}/share/blesh";
    LIBRARY_PATH = "/run/current-system/sw/lib";
    # environment.variables.GEMINI_API_KEY = "YOUR_API_KEY"; # OPTIONAL - For Gemini CLI
  };
  environment.pathsToLink = ["/lib/pkgconfig" "/share/pkgconfig" "/include" "/lib"];

  # Ensure dev outputs are available so .pc files exist
  environment.extraOutputsToInstall = ["dev"];

  # Build PKG_CONFIG_PATH dynamically at login
  environment.loginShellInit = ''
    pc_path=""
    # Scan only the system profile (not the whole store)
    while IFS= read -r d; do
      [ -d "$d" ] && pc_path="''${pc_path:+$pc_path:}$d"
    done <<EOF
    $(find -L /run/current-system/sw -type d \( -path '*/lib/pkgconfig' -o -path '*/share/pkgconfig' \) 2>/dev/null | sort -u)
    EOF
    export PKG_CONFIG_PATH="''${pc_path}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  '';

  # Enable experimental nix-command and flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Increase the download buffer size
  nix.settings.download-buffer-size = 524288000;

  # Allow unfree and broken packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # NixOS garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Load the kernel module for Silicon Labs USB-to-UART bridges. For the homeassistant yellow
  boot.kernelModules = ["cp210x"];

  # Serial port hygiene: prevent ModemManager from grabbing MCU/dev boards
  networking.modemmanager.enable = false;

  # Ensure ModemManager (if present) ignores Espressif and Silicon Labs serial interfaces
  services.udev.extraRules = ''
    # Espressif (USB-CDC ACM) - ESP32-S2/S3/H2 native USB and USB-Serial-JTAG
    ACTION=="add|change", SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_PORT_IGNORE}="1"
    # Silicon Labs (CP210x and CDC ACM variants)
    ACTION=="add|change", SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_PORT_IGNORE}="1"
  '';

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Some programs need SUID wrappers or run in user sessions
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      UseDns = false;
    };
  };

  # VSCode Server
  services.vscode-server.enable = true;

  # Container
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.containers.enable = true;
  virtualisation.containers.registries.search = ["docker.io"];
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    enable = true;
    rootless.enable = false;
    rootless.setSocketVariable = false;
    daemon.settings = {
      ipv6 = true;
      fixed-cidr-v6 = "fd00::/64";
      data-root = "/mnt/docker-data";
    };
  };

  # Ensure docker socket has correct permissions for group access
  systemd.services.docker.serviceConfig.ExecStartPost = [
    "${pkgs.coreutils}/bin/chmod 0660 /var/run/docker.sock"
  ];

  # Kernel sysctl settings
  boot.kernel.sysctl = {
    # Unrestrict ports below 1000
    "net.ipv4.ip_unprivileged_port_start" = 0;

    "net.ipv6.conf.all.forwarding" = 1; # Enable IPv6 forwarding globally
    "net.ipv6.conf.all.accept_ra" = 2; # Accept RA even with forwarding (overrides your =0)
    "net.ipv6.conf.default.accept_ra" = 2; # Accept RA for default interface
    "net.ipv6.conf.all.autoconf" = 1; # Enable SLAAC for IPv6 addresses (overrides your =0)
    "net.ipv6.conf.default.autoconf" = 1; # Enable SLAAC for default interface
    "net.ipv6.conf.all.accept_ra_rt_info_max_plen" = 64; # Allow /64 prefix routes from RA
    "net.ipv6.conf.end0.accept_ra_rt_info_max_plen" = 64; # Specific to OTBR infra interface
  };

  # Syncthing (disabled by default)
  services.syncthing = {
    enable = false;
    user = "tim";
    dataDir = "/home/tim";
    configDir = "/home/tim/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "tim-server" = {
          id = "ZKX6K7U-XPIMO7N-QM7KBU7-5OPVX7S-3E4UDW7-YKQBR2P-ZU4DC3F-ZYC34A3";
          autoAcceptFolders = true;
        };
      };
      folders = {
        "Home" = {
          path = "/home/tim";
          devices = ["tim-server"];
          addresses = ["tcp://10.0.0.2:22000"];
        };
      };
    };
  };

  users.users =
    lib.mapAttrs (_name: user: {
      isNormalUser = true;
      description = user.fullName;
      hashedPassword = user.hashedPassword;
      extraGroups = ["networkmanager" "wheel" "dialout" "uucp" "docker" "i2c"];
      openssh.authorizedKeys.keys = user.authorizedKeys or [];
    })
    users;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    tree
    blesh
    wl-clipboard
    osc
    starship
    zoxide
    dconf2nix
    btop
    docker
    docker-compose
    nerd-fonts.jetbrains-mono
    switcheroo-control
    ssh-to-age
    atuin
    sops
    gnugrep
    gawk
    gnused
    getent
    nodejs
  ];

  networking.hostName = hostName;

  networking.extraHosts =
    lib.concatStringsSep "\n"
    (lib.mapAttrsToList (name: ip: "${ip} ${name}") hostIps);

  ##########################################################################
  ## Docker bridge network creation – run once at boot, ensure it exists ##
  ##########################################################################
  systemd.services.docker-network-create = {
    description = "Ensure docker bridge network “docker-network” exists";
    after = ["docker.service"];
    wantedBy = ["docker.service" "multi-user.target"];

    serviceConfig = {Type = "oneshot";};

    script = ''
      set -euo pipefail

      # --- Wait until Docker answers -------------------------------------------------
      for i in {1..30}; do
        if ${dockerBin} info >/dev/null 2>&1; then
          break
        fi
        sleep 1
      done || {
        echo "Docker daemon did not become ready within 30 s" >&2
        exit 1
      }

      # --- Create network if missing -------------------------------------------------
      if ! ${dockerBin} network inspect docker-network >/dev/null 2>&1; then
        echo "Creating bridge network docker-network"
        ${dockerBin} network create \
          --driver bridge \
          --subnet 172.18.0.0/16 \
          --gateway 172.18.0.1 \
          docker-network
      else
        echo "Bridge network docker-network already exists"
      fi
    '';
  };

  ##########################################################################
  ## Firefox GNOME theme – run once at boot, fix every user’s profile    ##
  ##########################################################################
  systemd.services."firefox-theme-activation" = {
    description = "Ensure Firefox GNOME theme userContent.css is imported for all users";
    after = ["local-fs.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {Type = "oneshot";};

    script = ''
      # Iterate over every “real” user account
      getent passwd | awk -F: '$3 >= 1000 && $7 !~ /(false|nologin)/ {print $1}' |
      while read -r user; do
        home="$(getent passwd "$user" | cut -d: -f6)"
        profileDir="$home/.mozilla/firefox/default/chrome"

        mkdir -p "$profileDir"
        [ -s "$profileDir/userContent.css" ] || : > "$profileDir/userContent.css"

        if ! grep -Fxq '@import "firefox-gnome-theme/userContent.css";' \
                      "$profileDir/userContent.css"
        then
          sed -i '1i@import "firefox-gnome-theme/userContent.css";' \
              "$profileDir/userContent.css"
        fi

        chown -R "$user":"$(id -gn "$user")" "$home/.mozilla"
      done
    '';
  };

  ##########################################################################
  ## Discord Flatapk Rich Presence IPC socket fix                         ##
  ##########################################################################
  systemd.tmpfiles.rules = [
    # type  path                           mode uid gid age  target
    "L!     /run/user/%u/discord-ipc-0     -    -   -   -    /run/user/%u/app/com.discordapp.Discord/discord-ipc-0"
  ];

  # TTY Console
  console = {
    earlySetup = true; # apply before the login prompt
    # font = "ter-v32n"; # 16 × 32 Terminus, good for Hi-DPI
    # packages = with pkgs; [terminus_font]; # make sure the PSF is present
    keyMap = "de-latin1-nodeadkeys";
  };

  home-manager.sharedModules = [
    {
      home.stateVersion = "25.05";
      home.file = {
        ".bash_profile" = {
          source = builtins.toPath ../files/bash_profile;
          force = true;
        };
        ".bashrc" = {
          source = builtins.toPath ../files/bashrc;
          force = true;
        };
        ".config/starship.toml" = {
          source = builtins.toPath ../files/starship.toml;
          force = true;
        };
        # Claude Code shared environment
        ".claude/env.sh" = {
          source = builtins.toPath ../files/.claude/env.sh;
          executable = true;
        };
        ".claude/hooks/pre-tool-use.sh" = {
          source = builtins.toPath ../files/.claude/hooks/pre-tool-use.sh;
          executable = true;
        };
        ".claude/hooks/stop-off-topic-check.sh" = {
          source = builtins.toPath ../files/.claude/hooks/stop-off-topic-check.sh;
          executable = true;
        };
        # Claude Code commands
        ".claude/commands/commit.md" = {
          source = builtins.toPath ../files/.claude/commands/commit.md;
        };
        ".claude/commands/push.md" = {
          source = builtins.toPath ../files/.claude/commands/push.md;
        };
      };

      programs.atuin = {
        enable = true;
        # https://github.com/nix-community/home-manager/issues/5734
      };
    }
  ];

  home-manager.users.root = {
    # Files and folders to be symlinked into home
    home.file = {
      ".config/starship.toml" = lib.mkForce {
        source = builtins.toPath ../files/starship-root.toml;
        force = true;
      };
    };
  };

  virtualisation.oci-containers.containers = {
    # -------------------------------------------------------------------------
    # watchtower - automatically update containers
    # -------------------------------------------------------------------------
    watchtower = {
      image = "containrrr/watchtower";
      autoStart = true;

      autoRemoveOnStop = false; # prevent implicit --rm

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:rw"
      ];

      environment = {
        # Keep default 24-hour poll interval
        WATCHTOWER_POLL_INTERVAL = "86400"; # 24 hours in seconds
        # Cleanup old images after updating
        WATCHTOWER_CLEANUP = "true";
        # Set timezone for logs
        TZ = "Europe/Berlin";
        # Enable debug logging for better visibility
        WATCHTOWER_DEBUG = "true";
      };
    };

    # -------------------------------------------------------------------------
    # mcp-toolbox - MCP servers for Claude Code
    # -------------------------------------------------------------------------
    mcp-toolbox = {
      image = mcpToolboxImage;
      autoStart = true;

      autoRemoveOnStop = true;
      extraOptions = ["--network=docker-network" "--ip=172.18.0.15"];

      volumes = [
        "/mnt/docker-data/volumes/mcp-toolbox:/app/servers:rw"
      ];

      environmentFiles = [
        "/run/secrets/mcpToolboxENV"
      ];
    };
  };

  ##########################################################################
  ## Watchtower immediate startup check service                           ##
  ##########################################################################
  systemd.services.watchtower-startup-check = {
    description = "Run Watchtower check immediately on startup";
    after = ["docker-watchtower.service"];
    wants = ["docker-watchtower.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
    };

    script = ''
      set -euo pipefail

      # Wait a moment for watchtower container to be fully started
      sleep 10

      # Run a one-time watchtower check immediately
      ${dockerBin} run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e WATCHTOWER_CLEANUP=true \
        -e TZ=Europe/Berlin \
        -e WATCHTOWER_DEBUG=true \
        containrrr/watchtower \
        --run-once

      echo "Initial Watchtower check completed"
    '';
  };

  ##########################################################################
  ## MCP Toolbox volume permissions - make accessible to users            ##
  ##########################################################################
  systemd.services.mcp-toolbox-permissions = {
    description = "Set permissions on mcp-toolbox volume for user access";
    after = ["docker.service" "docker-mcp-toolbox.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail

      VOLUME_PATH="/mnt/docker-data/volumes/mcp-toolbox"

      if [ -d "$VOLUME_PATH" ]; then
        echo "Setting permissions on $VOLUME_PATH..."

        # Set execute-only ACL on parent directories for traversal (no read access)
        ${pkgs.acl}/bin/setfacl -m u:tim:x /mnt/docker-data
        ${pkgs.acl}/bin/setfacl -m u:tim:x /mnt/docker-data/volumes

        # Set full access on the volume directory and contents
        ${pkgs.acl}/bin/setfacl -R -m u:tim:rwX "$VOLUME_PATH"
        # Set default ACL so new files inherit permissions
        ${pkgs.acl}/bin/setfacl -R -d -m u:tim:rwX "$VOLUME_PATH"

        echo "MCP Toolbox volume permissions set successfully"
      else
        echo "Warning: $VOLUME_PATH does not exist yet"
      fi
    '';
  };

  ##########################################################################
  ## Home directory ownership correction service                          ##
  ##########################################################################
  systemd.services.fix-home-ownership = {
    description = "Fix ownership of user home directories";
    after = ["local-fs.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail

      echo "Fixing home directory ownership for all users..."

      # Iterate over every "real" user account (UID >= 1000, has valid shell)
      ${pkgs.getent}/bin/getent passwd | ${pkgs.gawk}/bin/awk -F: '$3 >= 1000 && $7 !~ /(false|nologin)/ {print $1}' |
      while read -r user; do
        home="$(${pkgs.getent}/bin/getent passwd "$user" | cut -d: -f6)"
        group="$(${pkgs.coreutils}/bin/id -gn "$user" 2>/dev/null || echo "users")"

        if [ -d "$home" ]; then
          echo "Fixing ownership for $user ($home)"
          ${pkgs.coreutils}/bin/chown -R "$user:$group" "$home" 2>/dev/null || {
            echo "Warning: Failed to fix ownership for some files in $home" >&2
          }
        fi
      done

      echo "Home directory ownership correction completed"
    '';
  };

  programs.ssh = {
    extraConfig = ''
      ServerAliveInterval 60
      ServerAliveCountMax 3

      # Using tim's SSH key as root's SSH key for GitHub
      Host github.com
        HostName github.com
        User git
        IdentityFile /home/tim/.ssh/id_ed25519
        IdentitiesOnly yes
    '';
  };

  ##########################################################################
  ## Setup home directory structure for all users                        ##
  ##########################################################################
  system.activationScripts.setupHomeStructure = {
    text = ''
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: user: ''
          home="$(${pkgs.getent}/bin/getent passwd "${name}" | cut -d: -f6)"
          if [ -n "$home" ] && [ -d "$home" ]; then
            echo "[home-structure] Setting up structure for ${name}"

            # Create Coding folder structure
            mkdir -p "$home/Coding/iocto"
            mkdir -p "$home/Coding/public_repos"
            mkdir -p "$home/Coding/private_repos"
            mkdir -p "$home/Coding/unreleased_repos"

            # Move FiraxisLive to hidden location (Civilization launcher folder)
            if [ -d "$home/FiraxisLive" ] && [ ! -d "$home/.FiraxisLive" ]; then
              mv "$home/FiraxisLive" "$home/.FiraxisLive"
              echo "Moved FiraxisLive to .FiraxisLive"
            elif [ -d "$home/FiraxisLive" ] && [ -d "$home/.FiraxisLive" ]; then
              echo "Warning: Both FiraxisLive and .FiraxisLive exist, skipping move"
            fi

            # Move PDX to hidden location (Paradox launcher folder)
            if [ -d "$home/PDX" ] && [ ! -d "$home/.PDX" ]; then
              mv "$home/PDX" "$home/.PDX"
              echo "Moved PDX to .PDX"
            elif [ -d "$home/PDX" ] && [ -d "$home/.PDX" ]; then
              echo "Warning: Both PDX and .PDX exist, skipping move"
            fi

            ${pkgs.coreutils}/bin/chown -R "${name}:users" "$home/Coding"
          fi
        '')
        users)}
    '';
    deps = [];
  };

  ##########################################################################
  ## Clone all timlisemer GitHub repositories                            ##
  ##########################################################################
  system.activationScripts.cloneGitHubRepos = {
    text = ''
      echo "[github-repos] Checking SSH access to GitHub..."
      if ! ${pkgs.openssh}/bin/ssh -T git@github.com 2>&1 | ${pkgs.gnugrep}/bin/grep -q "successfully authenticated"; then
        echo "[github-repos] SSH access not available, skipping clone"
      else
        echo "[github-repos] SSH access confirmed"

        # Parent must exist - created by setupHomeStructure
        if [ ! -d /home/tim/Coding/public_repos ]; then
          echo "[github-repos] ERROR: /home/tim/Coding/public_repos does not exist"
          exit 1
        fi

        # Add openssh to PATH so git can find ssh
        export PATH="${pkgs.openssh}/bin:$PATH"

        # Clone nixos config repo
        TARGET="/home/tim/Coding/nixos"
        if [ ! -d "$TARGET" ]; then
          echo "[github-repos] Cloning nixos config"
          ${pkgs.git}/bin/git clone "git@github.com:timlisemer/nixos.git" "$TARGET"
          ${pkgs.coreutils}/bin/chown -R tim:users "$TARGET"
        fi

        # Fetch repository list and clone
        REPOS=$(${pkgs.curl}/bin/curl -s "https://api.github.com/users/timlisemer/repos?per_page=100" | ${pkgs.jq}/bin/jq -r '.[].name')

        for repo in $REPOS; do
          # Skip nixos - already cloned to /home/tim/Coding/nixos
          if [ "$repo" = "nixos" ]; then
            continue
          fi
          TARGET="/home/tim/Coding/public_repos/$repo"
          if [ ! -d "$TARGET" ]; then
            echo "[github-repos] Cloning $repo"
            ${pkgs.git}/bin/git clone "git@github.com:timlisemer/$repo.git" "$TARGET"
          fi
        done

        # Chown parent recursively ONCE at the end
        ${pkgs.coreutils}/bin/chown -R tim:users /home/tim/Coding/public_repos

        echo "[github-repos] Public repos sync complete"

        # Clone private repositories if token is available
        GITHUB_TOKEN_FILE="/run/secrets/github_token"
        if [ -f "$GITHUB_TOKEN_FILE" ]; then
          GITHUB_TOKEN=$(${pkgs.coreutils}/bin/cat "$GITHUB_TOKEN_FILE")
          echo "[github-repos] Fetching private repositories..."

          # Check private_repos directory exists
          if [ ! -d /home/tim/Coding/private_repos ]; then
            echo "[github-repos] ERROR: /home/tim/Coding/private_repos does not exist"
            exit 1
          fi

          # Fetch private repos with authentication (get name and ssh_url)
          ${pkgs.curl}/bin/curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/user/repos?visibility=private&per_page=100" | \
            ${pkgs.jq}/bin/jq -r '.[] | "\(.name) \(.ssh_url)"' | \
          while read -r repo ssh_url; do
            TARGET="/home/tim/Coding/private_repos/$repo"
            if [ ! -d "$TARGET" ]; then
              echo "[github-repos] Cloning private repo: $repo"
              ${pkgs.git}/bin/git clone "$ssh_url" "$TARGET"
            fi
          done

          # Set ownership
          ${pkgs.coreutils}/bin/chown -R tim:users /home/tim/Coding/private_repos
          echo "[github-repos] Private repos sync complete"
        else
          echo "[github-repos] No GitHub token available, skipping private repos"
        fi
      fi
    '';
    deps = ["setupHomeStructure"];
  };

  ##########################################################################
  ## Setup Claude MCP servers                                             ##
  ##########################################################################
  system.activationScripts.claudeMcpSetup = {
    text = ''
      echo "[claude-mcp] Setting up MCP servers..."

      # Run as tim user since claude config is per-user
      ${pkgs.sudo}/bin/sudo -u tim ${unstable.claude-code}/bin/claude mcp list 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '/^[a-zA-Z0-9_-]+:/ {print $1}' | while read -r server; do
        echo "[claude-mcp] Removing server: $server"
        ${pkgs.sudo}/bin/sudo -u tim ${unstable.claude-code}/bin/claude mcp remove --scope user "$server" 2>/dev/null || true
      done

      echo "[claude-mcp] Adding nixos-search server..."
      ${pkgs.sudo}/bin/sudo -u tim ${unstable.claude-code}/bin/claude mcp add nixos-search --scope user -- ${dockerBin} exec -i mcp-toolbox sh -c 'exec 2>/dev/null; /app/tools/mcp-nixos/venv/bin/python3 -m mcp_nixos.server'

      echo "[claude-mcp] Adding tailwind-svelte server..."
      ${pkgs.sudo}/bin/sudo -u tim ${unstable.claude-code}/bin/claude mcp add tailwind-svelte --scope user -- ${dockerBin} exec -i mcp-toolbox node /app/tools/tailwind-svelte-assistant/run.mjs

      echo "[claude-mcp] Adding context7 server..."
      ${pkgs.sudo}/bin/sudo -u tim ${unstable.claude-code}/bin/claude mcp add context7 --scope user -- ${dockerBin} exec -i mcp-toolbox npx -y @upstash/context7-mcp

      echo "[claude-mcp] Adding agent-framework server..."
      ${pkgs.sudo}/bin/sudo -u tim ${unstable.claude-code}/bin/claude mcp add agent-framework --scope user -- \
        ${pkgs.nodejs}/bin/node /mnt/docker-data/volumes/mcp-toolbox/agent-framework/dist/mcp/server.js


      echo "[claude-mcp] MCP servers setup complete"
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing it read the docs (e.g. man configuration.nix or
  # https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
