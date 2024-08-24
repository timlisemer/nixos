# NixOS Configuration Repository

This repository contains my personal configuration for NixOS, a Linux distribution known for its declarative configuration model and reliable system management. 

## How to Use This Configuration

To use this NixOS configuration on your system, follow these steps:

### 1. Clone the Repository:

Clone the repository from GitHub to a temporary directory, such as `/tmp`.

```bash
git clone https:github.com/TimLisemer/NixOs.git /tmp/nixos-config
```

### 2. Move the Configuration to `/etc/nixos`:

Move the cloned configuration files to `/etc/nixos` and replace the existing configuration files.

```bash
sudo rm -rf /etc/nixos/*
sudo mv /tmp/nixos-config/* /etc/nixos/
```

### 3. Apply the Configuration for the First Time:

- For `tim-pc`, use the following command:

```bash
sudo nixos-rebuild switch --flake '.#tim-pc'
```

- For `tim-laptop`, use the following command:

```bash
sudo nixos-rebuild switch --flake '.#tim-laptop'
```

### 4. Rebuild the Configuration in the Future:

After the initial setup, you can rebuild the configuration with just:

```bash
sudo nixos-rebuild switch
```

This setup allows you to manage different machines (e.g., `tim-pc`, `tim-laptop`) using a shared configuration repository with host-specific adjustments.
