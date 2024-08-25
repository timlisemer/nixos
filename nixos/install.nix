# install.nix

{ disks ? [ "/dev/nvme0n1" ], ... }:
let 
  number_of_disks = if (builtins.length disks < 3) 
                    then builtins.length disks 
                    else throw "Error. Too many disks passed to disko.";
in
{
  disko.devices = {
    disk1 = {
      device = builtins.elemAt disks 0;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "500M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; 
              subvolumes = {
                "@" = { };
                "@/root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@/home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" ];
                };
                "@/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@/persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@/var-lib" = {
                  mountpoint = "/var/lib";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@/var-log" = {
                  mountpoint = "/var/log";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@/var-tmp" = {
                  mountpoint = "/var/tmp";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };

    disk2 = if (number_of_disks == 1) then {}
    else
    {
      device = builtins.elemAt disks 1;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          DATA = {
            type = "btrfs";
            extraArgs = [ "-f" ]; 
            subvolumes = {
              "@" = { 
                mountpoint = "/DATA";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@/home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" ];
              };
            };
          };
        };
      };
    };
  };
}
