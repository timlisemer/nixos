{ disks ? [ "/dev/nvme0n1" ], ... }:
let 
  number_of_disks = if (builtins.length disks < 3) 
                    then builtins.length disks 
                    else throw "Error. Too many disks passed to disko.";
in
{
  disko.devices = {
    disk = builtins.listToAttrs (
      [
        {
          name = "disk1";
          value = {
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
                    };
                  };
                };
              };
            };
          };
        }
      ] ++ (
        if number_of_disks > 1 then [
          {
            name = "disk2";
            value = {
              device = builtins.elemAt disks 1;
              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  DATA = {
                    size = "100%";
                    content = {
                      type = "btrfs";
                      mountOptions = [ "compress=zstd" "noatime" ];
                      extraArgs = [ "device add" (builtins.elemAt disks 1) ];
                      mountpoint = "/"; # Added to the Btrfs pool on disk1
                    };
                  };
                };
              };
            };
          }
        ] else []
      )
    );
  };
}
