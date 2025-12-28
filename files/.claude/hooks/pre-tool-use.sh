#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
exec node "$AGENT_FRAMEWORK_HOOKS/pre-tool-use.js"
