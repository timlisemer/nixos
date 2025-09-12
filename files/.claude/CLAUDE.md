## Code Style
- No emojis in code
- Use descriptive variable names

## Command Preferences  
- Use `make check`, `cargo check`, `cargo test` instead of build/run commands
- Ask user to execute build/run commands when needed

## Error Handling
- When tool calls fail: explicitly state the error and your fix approach before retrying; persist until successful

## Documentation Tools
- Always use Context7 MCP tools for code generation, setup/configuration steps, or library/API documentation
- Exception: use README.md for iocto libs

## Build/Run Command Restrictions
- Always prefer Makefile/project build systems over individual commands
- Never run build/run-like commands autonomously (make build, make run, cargo run, npm start, etc.)
- Only run test/check-like commands (make test, cargo test, cargo check, npm run check, etc.)
- Always ask user to execute build/run commands

## File Creation Restrictions
- Never create temporary files without asking user first
- If you feel you need temporary files, rethink your approach
- Prefer editing existing files over creating new ones

## Code Formatting Requirements
- Always run available code formatters before presenting solutions
- Only present solutions after formatting passes without errors

## System Safety
- Never run permanent system-changing commands autonomously
- Only use testing/validation commands
- User must manually run permanent changes after review

## Project Documentation Priority
- Use project-specific documentation (README.md) over general tools when explicitly mentioned

## Database Inspection (Pre-approved Commands)
- Always use sqlite3 commands for database exploration instead of asking user
- Use .tables, .schema, SELECT *, PRAGMA, EXPLAIN, .dump commands freely
- These are read-only operations that are safe and pre-approved

## Development Workflow (Pre-approved Commands)
- Always check IDE diagnostics (`mcp__ide__getDiagnostics`) first for quick feedback
- Always run `make check` when available (preferred comprehensive validation)
- Fallback to individual commands only when `make check` unavailable: `cargo check`, `cargo test`, `npm run check`, etc.
- Always run `alejandra` formatter for Nix files

## Search and Discovery (Pre-approved Commands)
- Use grep and find commands freely for code exploration
- Use AWS S3 listing commands when working with cloud storage

## Documentation Access (Pre-approved Commands)
- Proactively fetch documentation from pre-approved domains (github.com, docs.rs, nixos.org, tailwindcss.com, svelte.dev, tauri.app)
- Use MCP documentation tools (NixOS search, Tailwind/Svelte docs) automatically when relevant

## System Information
- User runs Linux Wayland NixOS with custom configuration
- System config available at: https://github.com/timlisemer/nixos/tree/main
