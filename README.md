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

#### 2.1 Optionally enable ssh access within the Live Environment:

```bash
passwd nixos
```

This allows you to do 
```bash
ssh nixos@<hostname>
```

### 3. Clone the Repository:

Clone the repository from GitHub to a temporary directory, such as `/tmp`.

```bash
git clone https://github.com/TimLisemer/NixOs.git /tmp/nixos
```

### 3.1 Optionally generate Hardware config

```bash
sudo nixos-generate-config --no-filesystems --show-hardware-config >> hardware-configuration.nix
```

Afterwards move it for example into /tmp/nixos/hosts with a correct name.

### 4. Mount & install NixOS using Disko:

To mount and install the filesystem using Disko, use the following commands. Make sure to specify the correct disk(s) for your machine.

- **For `tim-laptop` (single disk):**

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount /tmp/nixos/install.nix --arg disks '[ "/dev/nvme0n1" ]'

sudo nixos-install --flake '/tmp/nixos/flake.nix#tim-laptop'
```

- **For `tim-pc` (dual disk):**

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode zap_create_mount /tmp/install.nix --arg disks '[ "/dev/nvme0n1" "/dev/nvme1n1" ]'

sudo nixos-install --flake '/tmp/nixos/flake.nix#tim-pc'
```

### 5. Boot into the Newly Installed System:

After the installation completes, reboot your system into the newly installed NixOS.

### 6. Finish Installation

Once booted, set the password for the user account

If in a display manager switch to a tty: CTRL + ALT + (F1 - F12)

Login with the root account and then replace tim  with the username of you configuration:

```bash
passwd tim
```

### 7. Rebuild the Configuration in the Future:

After the initial setup, you can rebuild the configuration with just:

```bash
sudo nixos-rebuild switch
```

This setup allows you to manage different machines (e.g., `tim-pc`, `tim-laptop`) using a shared configuration repository with host-specific adjustments.
