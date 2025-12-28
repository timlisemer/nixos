#!/usr/bin/env bash
# Shared environment setup for all Claude Code hooks
# Source this in hook wrappers: source "$(dirname "$0")/env.sh"

# Source API keys from SOPS secrets (with auto-export)
if [[ -f /run/secrets/mcpToolboxENV ]]; then
  set -a  # Enable auto-export
  source /run/secrets/mcpToolboxENV
  set +a  # Disable auto-export
fi

# Agent framework paths
export AGENT_FRAMEWORK_DIR="/mnt/docker-data/volumes/mcp-toolbox/agent-framework"
export AGENT_FRAMEWORK_HOOKS="$AGENT_FRAMEWORK_DIR/dist/hooks"
