#!/usr/bin/env bash
# Shared environment setup for Claude Code hooks, MCP servers, and commands
# Called via run-with-env.sh wrapper

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
