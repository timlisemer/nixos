{ disks ? [ "/dev/nvme0n1" "/dev/nvme1n1" ], ... }:
let
  number_of_disks = builtins.length disks;
in
{
  disko.devices = {
    disk = builtins.listToAttrs (
      builtins.genList (index:
        let
          diskName = "disk${toString (index + 1)}";
        in
        {
          name = diskName;
          value = {
            device = builtins.elemAt disks index;
            type = "disk";
            content = {
              type = "gpt";
              partitions = if index == 0 then {
                boot = {
                  size = "512M";
                  type = "EF00";
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
                    extraArgs = if number_of_disks > 1 
                                then [ "-f" "-d" "raid0" "-m" "raid0" ] 
                                else [ "-f" ];
                    subvolumes = {
                      "@" = { };
                      "@root" = {
                        mountpoint = "/";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      "@home" = {
                        mountpoint = "/home";
                        mountOptions = [ "compress=zstd" ];
                      };
                      "@nix" = {
                        mountpoint = "/nix";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                    };
                  };
                };
              } else {
                root = {
                  size = "100%";
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                  };
                };
              };
            };
          };
        }
      ) number_of_disks
    );
  };
}
