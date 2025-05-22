{disks ? ["/dev/nvme0n1"], ...}: let
  disk_path = builtins.elemAt disks 0;
in {
  disko.devices = {
    disk = {
      "${disk_path}" = {
        device = "${disk_path}";
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
