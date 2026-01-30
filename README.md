# NixOS Configuration Repository

This repository contains my personal configuration for NixOS, a Linux distribution known for its declarative configuration model and reliable system management.

## Installation Methods

### Method 1: Remote Install (Recommended)

Use this method from an existing NixOS machine with SSH keys configured.

```bash
install_nixos <hostname>

# Examples:
install_nixos tim-laptop
install_nixos tim-pc
install_nixos tim-server
install_nixos homeassistant-yellow
```

This builds locally and deploys remotely with integrated key transfer.

### Method 2: USB Install with Passkey

For fresh installations from NixOS live USB (requires homeassistant-yellow on local network).

#### First-time Setup (one-time)

Register a passkey on your phone:

1. Open `https://homeassistant-yellow.local:8901/register/begin` on your phone
2. Follow prompts to register with Bitwarden (or another passkey provider)

#### Installation

From a NixOS live USB:

```bash
curl http://homeassistant-yellow.local:8900/install | bash
```

1. Scan the QR code with your phone
2. Authenticate with your registered passkey
3. Follow the on-screen instructions to complete installation

## Disk Configurations

| Host | Disks |
|------|-------|
| tim-laptop | `/dev/nvme0n1` |
| tim-pc | `/dev/nvme0n1`, `/dev/nvme1n1` |
| tim-server | `/dev/sda` |

## Rebuilding

```bash
rebuild                    # Local rebuild
remote_rebuild <hostname>  # Remote rebuild
```
