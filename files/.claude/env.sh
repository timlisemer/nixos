#!/usr/bin/env bash
# Shared environment setup for Claude Code hooks and commands
# Source this in hook/command wrappers: source "$(dirname "$0")/../env.sh"

# Source API keys from SOPS secrets (with auto-export)
if [[ -f /run/secrets/mcpToolboxENV ]]; then
  set -a # Enable auto-export
  source /run/secrets/mcpToolboxENV
  set +a # Disable auto-export
fi

# Export webhook secrets for hook scripts
if [[ -f /run/secrets/webhook_id_agent_logs ]]; then
  export WEBHOOK_ID_AGENT_LOGS=$(cat /run/secrets/webhook_id_agent_logs)
fi

# Agent framework paths
export AGENT_FRAMEWORK_DIR="/mnt/docker-data/volumes/mcp-toolbox/agent-framework"
export AGENT_FRAMEWORK_HOOKS="$AGENT_FRAMEWORK_DIR/dist/hooks"
