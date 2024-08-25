# NixOS Configuration Repository

This repository contains my personal configuration for NixOS, a Linux distribution known for its declarative configuration model and reliable system management. 

## How to Use This Configuration

To use this NixOS configuration on your system, follow these steps:

### 1. Boot into the Minimal NixOS Live CD:

Boot your system using a NixOS live CD or USB.

### 2. Prepare the Live Environment:

Since the minimal NixOS environment does not have `git` installed by default, install it with the following command:

```bash
nix-env -iA nixos.git
```

### 3. Clone the Repository:

Clone the repository from GitHub to a temporary directory, such as `/tmp`.

```bash
git clone https://github.com/TimLisemer/Dotfiles.git /tmp/nixos-config
```

### 4. Prepare the Configuration for Installation:

Move the cloned NixOS configuration files from the `/nixos` directory to `/etc/nixos` and replace the existing configuration files.

```bash
sudo rm -rf /etc/nixos/*
sudo mv /tmp/nixos-config/nixos/* /etc/nixos/
```

### 5. Install NixOS Using Disko:

To install NixOS using the Disko configuration, use the following commands. Make sure to specify the correct disk(s) for your machine.

- **For `tim-laptop` (single disk):**

```bash
sudo nix run 'github:nix-community/disko#disko-install' -- --flake '/etc/nixos#install' --disk 'disk1' '/dev/nvme0n1'
```

- **For `tim-pc` (dual disk):**

```bash
sudo nix run 'github:nix-community/disko#disko-install' -- --flake '/etc/nixos#install' --disk 'disk1' '/dev/nvme0n1' --disk 'disk2' '/dev/nvme1n1'
```

### 6. Boot into the Newly Installed System:

After the installation completes, reboot your system into the newly installed NixOS.

### 7. Apply the Host-Specific Configuration:

Once booted, apply the host-specific configuration. For example:

- For `tim-pc`, use the following command:

```bash
sudo nixos-rebuild switch --flake '.#tim-pc'
```

- For `tim-laptop`, use the following command:

```bash
sudo nixos-rebuild switch --flake '.#tim-laptop'
```

### 8. Rebuild the Configuration in the Future:

After the initial setup, you can rebuild the configuration with just:

```bash
sudo nixos-rebuild switch
```

This setup allows you to manage different machines (e.g., `tim-pc`, `tim-laptop`) using a shared configuration repository with host-specific adjustments.
