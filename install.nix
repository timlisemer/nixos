{ pkgs ? import <nixpkgs> {} }:

let
  # Define the number of disks based on the passed argument
  number_of_disks = builtins.length (import ./config.nix).disks;

in
{
  # Use disko to create partitions
  networking = {
    networkmanager.enable = true;
  };

  disko = {
    devices = [
      {
        device = "/dev/nvme0n1";
        partitions = {
          type = "gpt";
          subvolumes = {
            boot = {
              mountPoint = "/boot";
              fsType = "vfat";
              extraArgs = [];
              size = "500M";
            };
            root = {
              mountPoint = "/";
              fsType = "btrfs";
              # Set up RAID 0 across the two disks if there are more than one
              extraArgs = if number_of_disks > 1 then [ "-d" "raid0" "-m" "raid0" ] else [ "-f" ];
              subvolumes = {};
            };
          };
        };
      }
      # Second disk is only included if there is more than one disk
      (if number_of_disks > 1 then
        {
          device = "/dev/nvme1n1";
          partitions = {
            type = "gpt";
            subvolumes = {
              root = {
                mountPoint = "/"; # Mount point for the root filesystem is still "/"
                fsType = "btrfs";
                extraArgs = [ "-d" "raid0" "-m" "raid0" ]; # RAID 0 settings for the second disk
                subvolumes = {};
              };
            };
          };
        } else null)
    ];
  };
}
