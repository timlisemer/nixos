#!/usr/bin/env bash
exec "$(dirname "$0")/../run-with-env.sh" node "$AGENT_FRAMEWORK_HOOKS/pre-tool-use.js"
