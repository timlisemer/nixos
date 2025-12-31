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

    environmentFiles = [
      "/run/secrets/mcpToolboxENV"
    ];
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
        /home/tim/.claude/run-with-env.sh ${pkgs.nodejs}/bin/node /mnt/docker-data/volumes/mcp-toolbox/agent-framework/dist/mcp/server.js


      echo "[claude-mcp] MCP servers setup complete"
    '';
  };

  ##########################################################################
  ## Claude Code shared environment and hooks                             ##
  ##########################################################################
  home-manager.sharedModules = [
    {
      home.file = {
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
        ".claude/hooks/post-tool-use.sh" = {
          source = builtins.toPath ../files/.claude/hooks/post-tool-use.sh;
          executable = true;
        };
        ".claude/run-with-env.sh" = {
          source = builtins.toPath ../files/.claude/run-with-env.sh;
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
    }
  ];
}
