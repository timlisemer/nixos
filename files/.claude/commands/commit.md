---
description: Commit staged changes with auto-generated message
allowed-tools: mcp__agent-framework__commit
---

1. Use the mcp__agent-framework__commit tool to generate and execute a commit
2. Check the result:
   - If it starts with "SKIPPED:" - report that nothing was committed
   - If it contains an error or failure - report the error
   - Otherwise - report the commit hash to the user
