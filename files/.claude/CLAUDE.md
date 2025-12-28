# AI Behavior & Workflow Guidelines

## Code & Style

- **Style:** Use descriptive variable names. No emojis in code.
- **Legacy Code:** Do not leave unused code; remove unless explicitly mentioned.
- **File Management:** Prefer editing existing files. Never create temporary files without permission.

## Permissions & Safety

- **User Execution Required:** Build commands, run commands, and permanent system-changing commands.
- **Pre-approved (Autonomous):** - `sqlite3` read-only commands (`.tables`, `.schema`, `SELECT`, `.dump`, `PRAGMA`).
  - AWS S3 listing commands.
  - Websearch and fetching docs from trusted domains (github.com, docs.rs, nixos.org, tailwindcss.com, svelte.dev, tauri.app).

## Development Workflow

1. **Diagnostics:** Always check `mcp__ide__getDiagnostics` first.
2. **Formatting:** Always run `alejandra` for Nix files. Ensure no formatting errors exist before presenting solutions.
3. **Final Step:** Always run `check` mcp server.

## Documentation & Tools

- **Primary:** Use Context7 MCP tools for code generation, setup, and library docs.
- **Exception:** Use the different `README.md` for iocto libs.
- **Error Handling:** If a tool fails, explicitly state the error and fix approach, then persist until successful.

## System Context

- **OS:** Linux Wayland NixOS.
- **Configuration:** [timlisemer/nixos](https://github.com/timlisemer/nixos/tree/main)
