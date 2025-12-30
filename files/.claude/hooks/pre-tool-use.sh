#!/usr/bin/env bash
exec "$(dirname "$0")/../run-with-env.sh" node /mnt/docker-data/volumes/mcp-toolbox/agent-framework/dist/hooks/pre-tool-use.js
