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

  # Use disko to handle disk operations
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
              extraArgs = if number_of_disks > 1 then [ "-d" "raid0" "-m" "raid0" ] else [ "-f" ];
              subvolumes = {};
            };
          };
        };
      }
      # Include additional disks if necessary
      (if number_of_disks > 1 then
        {
          device = "/dev/nvme1n1";
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
                extraArgs = if number_of_disks > 1 then [ "-d" "raid0" "-m" "raid0" ] else [ "-f" ];
                subvolumes = {};
              };
            };
          };
        } else null)
    ];
  };
}
