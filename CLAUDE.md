# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS configuration repository that uses Nix flakes to manage multiple systems declaratively. It configures desktop systems (tim-laptop, tim-pc), servers (tim-server, homeassistant-yellow, tim-pi4), and WSL environments.

## IMPORTANT: Recommended Tool Usage

### NixOS MCP Server (HIGHLY RECOMMENDED)

**Always use the NixOS MCP server tools when working with Nix/NixOS configurations.** These tools provide accurate, up-to-date information about packages, options, and configurations:

- **`mcp__nixos-search__nixos_search`**: Search for NixOS packages, options, programs, or flakes
- **`mcp__nixos-search__nixos_info`**: Get detailed information about specific packages/options
- **`mcp__nixos-search__home_manager_search`**: Search Home Manager options
- **`mcp__nixos-search__home_manager_info`**: Get details about Home Manager options
- **`mcp__nixos-search__darwin_search`**: Search nix-darwin (macOS) options
- **`mcp__nixos-search__nixhub_package_versions`**: Find specific package versions with commit hashes
- **`mcp__nixos-search__nixos_flakes_search`**: Search community flakes

### Web Search

Use **WebSearch** as a secondary tool for:

- Recent NixOS news, updates, or community discussions
- Troubleshooting specific error messages
- Finding blog posts or tutorials about NixOS patterns

**Priority: Always try NixOS MCP tools first, then fall back to WebSearch if needed.**

## Architecture

The repository follows a modular structure:

- **`flake.nix`**: Central configuration defining all NixOS systems, users, and static IPs. Each host is defined via `mkSystem` with host-specific configurations.
- **`hosts/`**: Individual host configurations that import common modules and define machine-specific settings
- **`common/`**: Shared modules imported by hosts:
  - `common.nix`: Base system configuration
  - `disko.nix`: Declarative disk partitioning (supports multi-disk setups)
  - `home-manager.nix`: User environment configuration
  - `restic_backups.nix`: Automated backup configuration
  - `desktop-only.nix`: Desktop environment packages and settings
- **`desktop-environments/`**: Modular desktop environment configurations (GNOME, Hyprland, COSMIC)
- **`packages/`**: Custom package definitions
- **`secrets/`**: SOPS-encrypted secrets (uses age keys)

## Key Commands

### System Management

```bash
# Rebuild current system configuration
sudo nixos-rebuild switch

# Rebuild with specific flake
sudo nixos-rebuild switch --flake .#tim-laptop

# Update flake inputs
nix flake update

# Format Nix files (Alejandra is included in flake)
alejandra .
```

### Installation (from live ISO)

```bash
# Install for tim-laptop (single disk)
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount /tmp/nixos/common/disko.nix --arg disks '[ "/dev/nvme0n1" ]'
sudo nixos-install --flake '/mnt/etc/nixos#tim-laptop'

# Install for tim-pc (dual disk)
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount /tmp/nixos/common/disko.nix --arg disks '[ "/dev/nvme0n1" "/dev/nvme1n1" ]'
sudo nixos-install --flake '/mnt/etc/nixos#tim-pc'
```

### Development

```bash
# Test configuration without switching
sudo nixos-rebuild test

# Check Nix syntax
nix flake check

# Show flake outputs
nix flake show
```

## IMPORTANT: System Modification Restrictions

**Claude Code must NEVER run permanent system-changing commands.** Only testing and validation commands are allowed:

### Allowed Commands
```bash
# Test configuration without making permanent changes
sudo nixos-rebuild test
sudo nixos-rebuild dry-run

# Validation commands
nix flake check
alejandra --check .
```

### FORBIDDEN Commands
```bash
# NEVER run these - they make permanent system changes
sudo nixos-rebuild switch
sudo nixos-rebuild boot
sudo nixos-install
```

**The user must manually run any permanent system changes after reviewing and approving the configuration.**

## Configuration Patterns

### Adding a New Host

1. Create hardware configuration in `hosts/<hostname>-hardware-configuration.nix`
2. Create host configuration in `hosts/<hostname>.nix` importing common modules
3. Add host to `flake.nix` under `nixosConfigurations` using `mkSystem`
4. Add host IP to `hostIps` in `flake.nix`

### User Management

Users are defined centrally in `flake.nix` under the `users` attribute set. Each user requires:

- `fullName`, `gitUsername`, `gitEmail`
- `hashedPassword` (SHA-512 crypt)
- `authorizedKeys` list

### Secret Management

Uses SOPS with age keys derived from SSH keys:

- Configuration in `sops.yaml`
- Secrets stored in `secrets/secrets.yaml`
- Age keys expected at `~/.config/sops/age/keys.txt`

### Backup Configuration

Automated backups via Restic are configured in `common/restic_backups.nix`. Paths are defined in `flake.nix`:

- `userBackupDirs`: Standard user directories
- `userDotFiles`: Configuration directories

## Working with NixOS Options

When adding or modifying NixOS configurations:

1. **First** use `mcp__nixos-search__nixos_search` to find relevant options
2. **Then** use `mcp__nixos-search__nixos_info` to get detailed documentation
3. **For Home Manager**, use the corresponding `home_manager_*` MCP tools
4. **Only use WebSearch** if you need community examples or recent discussions

## Development Dependencies

### Adding System-Wide Development Libraries

Development dependencies are managed in two locations:

1. **`packages/dependencies.nix`**: Install development packages and libraries

   - Add packages with their `.dev` outputs when needed (e.g., `glib.dev`, `openssl.dev`)
   - This file is imported by all host configurations

2. **`common/common.nix`**: PKG_CONFIG_PATH is automatically configured
   - **PKG_CONFIG_PATH**: Dynamically built at login from all installed packages
   - Uses `environment.loginShellInit` to scan `/run/current-system/sw` for pkgconfig directories
   - No manual configuration needed - automatically finds all `.dev` packages from `dependencies.nix`
   - Configured with `environment.pathsToLink` and `environment.extraOutputsToInstall = ["dev"]`

### Example: Adding a New C Library Dependency for Rust

If you encounter build errors like "The system library `xyz` required by crate `xyz-sys` was not found":

1. Search for the package: `mcp__nixos-search__nixos_search` with query "xyz"
2. Add to `packages/dependencies.nix`: `xyz` and `xyz.dev` (both runtime and development packages)
3. Run `sudo nixos-rebuild switch` to apply changes
4. PKG_CONFIG_PATH will automatically include the new library's pkgconfig files

**No manual PKG_CONFIG_PATH configuration needed** - the system automatically detects all `.dev` packages.

## Code Formatting with Alejandra

**IMPORTANT: Always run alejandra to check and format Nix files before presenting any solution to the user.**

Alejandra is the Nix code formatter used in this project. It ensures consistent formatting across all Nix files.

### Usage

```bash
# Format all Nix files in the current directory and subdirectories
alejandra .

# Check formatting without modifying files (use this before presenting solutions)
alejandra --check .

# Format a specific file
alejandra <file>
```

### When working with Nix files:

1. Make your changes to the Nix configuration
2. **ALWAYS** run `alejandra --check .` to verify syntax and formatting
3. If formatting issues are found, run `alejandra .` to fix them
4. Only present the solution to the user after alejandra passes without errors
