{disks, ...}: let
  rawdisk1 = builtins.elemAt disks 0;
  rawdisk2 =
    if (builtins.length disks) > 1
    then builtins.elemAt disks 1
    else null;
in {
  disko.devices = {
    disk = {
      "${rawdisk1}" = {
        device = "${rawdisk1}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "EFI";
              name = "ESP";
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
              name = "btrfs";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs =
                  if rawdisk2 != null
                  then ["-f" "-d" "raid0" "-m" "raid0" rawdisk2]
                  else ["-f"]; # RAID0 if 2 disks, otherwise single disk
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
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
