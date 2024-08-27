# NixOS Configuration Repository

This repository contains my personal configuration for NixOS, a Linux distribution known for its declarative configuration model and reliable system management. 

## How to Use This Configuration

To use this NixOS configuration on your system, follow these steps:

### 1. Boot into the Minimal NixOS Live CD:

Boot your system using a NixOS live CD or USB.

### 2. Prepare the Live Environment:

If the minimal NixOS environment does not have `git` installed by default, install it with the following command:

```bash
nix-env -iA nixos.git
```

#### 2.1 Optionally Enable SSH Access Within the Live Environment:

To set a password for the `nixos` user, run:

```bash
passwd nixos
```

This allows you to SSH into the live environment using:

```bash
ssh nixos@<hostname>
```

### 3. Clone the Repository:

Clone the repository from GitHub to a temporary directory, such as `/tmp`.

```bash
git clone https://github.com/TimLisemer/NixOs.git /tmp/nixos
```

### 3.1 Optionally Generate Hardware Configuration:

Generate a hardware configuration without filesystem information and save it to `hardware-configuration.nix`:

```bash
sudo nixos-generate-config --no-filesystems --show-hardware-config >> hardware-configuration.nix
```

Move the generated file, for example, into `/tmp/nixos/hosts` with an appropriate name.

### 4. Mount the Filesystem Using Disko:

Use Disko to mount the filesystem by running the following commands. Ensure you specify the correct disk(s) for your machine.

- **For `tim-laptop` (single disk):**

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount /tmp/nixos/install.nix --arg disks '[ "/dev/nvme0n1" ]'
```

- **For `tim-pc` (dual disk):**

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount /tmp/install.nix --arg disks '[ "/dev/nvme0n1" "/dev/nvme1n1" ]'
```

### 5. Install NixOS:

Create the necessary directories and copy the configuration to the target filesystem:

```bash
sudo mkdir -p /mnt/etc/nixos
sudo cp -rT /tmp/nixos/* /mnt/etc/nixos/
```

- **For `tim-laptop`:**

```bash
sudo nixos-install --flake '/mnt/etc/nixos/flake.nix#tim-laptop'
```

- **For `tim-pc`:**

```bash
sudo nixos-install --flake '/mnt/etc/nixos/flake.nix#tim-pc'
```

### 6. Finalize Installation:

Set the password for each user account declared in the configuration:

```bash
sudo nixos-enter --root /mnt -c 'passwd tim'
```

### 7. Boot into the Newly Installed System:

After the installation completes, reboot your system into the newly installed NixOS.

### 8. Rebuild the Configuration in the Future:

After the initial setup, you can rebuild the configuration with the following command:

```bash
sudo nixos-rebuild switch
```

This setup allows you to manage different machines (e.g., `tim-pc`, `tim-laptop`) using a shared configuration repository with host-specific adjustments.
