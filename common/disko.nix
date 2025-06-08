# disko-two-disk-raid0.nix
{disks, ...}: let
  rawdisk1 = builtins.elemAt disks 0;
  rawdisk2 =
    if (builtins.length disks) > 1
    then builtins.elemAt disks 1
    else null;
in {
  disko.devices = {
    disk =
      # Process second disk first if it exists - use whole disk for BTRFS
      (
        if rawdisk2 != null
        then {
          ########################
          ## 2nd physical disk ##
          ########################
          "${rawdisk2}" = {
            device = rawdisk2;
            type = "disk";
            content = {
              # Use whole disk, no partitioning
              type = "btrfs";
            };
          };
        }
        else {}
      )
      //
      ########################
      ## 1st physical disk ##
      ########################
      {
        "${rawdisk1}" = {
          device = rawdisk1;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1M";
                type = "EF02";
              };
              ESP = {
                label = "EFI";
                size = "1024M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              root = {
                label = "rootfs";
                size = "100%";
                content = {
                  type = "btrfs";
                  # Add the 2nd-disk (whole disk) to the mkfs command when it exists
                  extraArgs =
                    if rawdisk2 != null
                    then ["-f" "-d" "raid0" "-m" "raid0" rawdisk2]
                    else ["-f"];
                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@/mnt/docker-data" = {
                      mountpoint = "/mnt/docker-data";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@/mnt/vm-data" = {
                      mountpoint = "/mnt/vm-data";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@/home" = {
                      mountpoint = "/home";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@/nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@/var_local" = {
                      mountpoint = "/var/local";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@/var_log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                  };
                };
              };
            };
          };
        };
      };
  };
}
