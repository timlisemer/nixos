{
  config,
  pkgs,
  inputs,
  lib,
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
  ##########################################################################
  ## MCP Toolbox Docker Container                                         ##
  ##########################################################################
  virtualisation.oci-containers.containers.mcp-toolbox = {
    image = mcpToolboxImage;
    autoStart = true;

    autoRemoveOnStop = true;
    extraOptions = ["--network=docker-network" "--ip=172.18.0.15"];

    volumes = [
      "/mnt/docker-data/volumes/mcp-toolbox:/app/servers:rw"
    ];

    environment = {
      TELEMETRY_HOST_ID = config.networking.hostName;
      TELEMETRY_ENDPOINT = "https://telemetry.yakweide.de";
      AGENT_FRAMEWORK_ROOT = "/mnt/docker-data/volumes/mcp-toolbox/agent-framework";
    };
  };

  ##########################################################################
  ## Sync secrets to agent-framework .env file                            ##
  ##########################################################################
  systemd.services.agent-framework-env-sync = {
    description = "Sync secrets to agent-framework .env file";
    after = ["sops-nix.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail

      TELEMETRY_SECRET="/run/secrets/telemetryENV"
      MCP_TOOLBOX_SECRET="/run/secrets/mcpToolboxENV"
      ENV_FILE="/mnt/docker-data/volumes/mcp-toolbox/agent-framework/.env"

      echo "Creating $ENV_FILE..."
      mkdir -p "$(dirname "$ENV_FILE")"

      # Start with empty file
      : > "$ENV_FILE"

      # Append telemetryENV if exists
      if [ -f "$TELEMETRY_SECRET" ]; then
        cat "$TELEMETRY_SECRET" >> "$ENV_FILE"
        echo "" >> "$ENV_FILE"
      else
        echo "Warning: $TELEMETRY_SECRET does not exist"
      fi

      # Append mcpToolboxENV if exists
      if [ -f "$MCP_TOOLBOX_SECRET" ]; then
        cat "$MCP_TOOLBOX_SECRET" >> "$ENV_FILE"
        echo "" >> "$ENV_FILE"
      else
        echo "Warning: $MCP_TOOLBOX_SECRET does not exist"
      fi

      # Append host-specific telemetry config
      echo "TELEMETRY_HOST_ID=${config.networking.hostName}" >> "$ENV_FILE"
      echo "TELEMETRY_ENDPOINT=https://telemetry.yakweide.de" >> "$ENV_FILE"

      chmod 644 "$ENV_FILE"
      echo "agent-framework .env file updated successfully"
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

      # Create symlink for claude commands
      rm -rf /home/tim/.claude/commands
      ln -sfn /mnt/docker-data/volumes/mcp-toolbox/agent-framework/commands /home/tim/.claude/commands
      chown -h tim:users /home/tim/.claude/commands

      # Create symlink for claude settings
      rm -rf /home/tim/.claude/settings.json
      ln -sfn /mnt/docker-data/volumes/mcp-toolbox/agent-framework/claude-integration/settings.json /home/tim/.claude/settings.json
      chown -h tim:users /home/tim/.claude/settings.json

      # Create symlink for claude hooks
      rm -rf /home/tim/.claude/hooks
      ln -sfn /mnt/docker-data/volumes/mcp-toolbox/agent-framework/dist/hooks /home/tim/.claude/hooks
      chown -h tim:users /home/tim/.claude/hooks
    '';
  };
}
