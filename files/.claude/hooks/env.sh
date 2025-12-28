#!/usr/bin/env bash
# Shared environment setup for all Claude Code hooks
# Source this in hook wrappers: source "$(dirname "$0")/env.sh"

# Source API keys from SOPS secrets
if [[ -f /run/secrets/mcpToolboxENV ]]; then
  source /run/secrets/mcpToolboxENV
fi

# Agent framework paths
export AGENT_FRAMEWORK_DIR="/mnt/docker-data/volumes/mcp-toolbox/agent-framework"
export AGENT_FRAMEWORK_HOOKS="$AGENT_FRAMEWORK_DIR/dist/hooks"
