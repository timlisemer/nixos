{
  config,
  pkgs,
  lib,
  backupPaths,
  hostName,
  inputs,
  ...
}: let
  getLocation = path: let
    cleanParts = lib.filter (x: x != "") (lib.splitString "/" path);
  in
    if (lib.hasPrefix "/home/" path) && (builtins.length cleanParts >= 2) && (builtins.elemAt cleanParts 0 == "home")
    then let
      username = builtins.elemAt cleanParts 1;
      subParts = lib.drop 2 cleanParts;
      subPathStr =
        if subParts == []
        then ""
        else "/" + lib.concatStringsSep "_" subParts;
    in
      "user_home/" + username + subPathStr
    else if (lib.hasPrefix "/mnt/docker-data/volumes/" path) && (builtins.length cleanParts >= 4) && (builtins.elemAt cleanParts 0 == "mnt") && (builtins.elemAt cleanParts 1 == "docker-data") && (builtins.elemAt cleanParts 2 == "volumes")
    then "docker_volume/" + (lib.concatStringsSep "_" (lib.drop 3 cleanParts))
    else "system";
in {
  imports = [inputs.restic-backup-service.nixosModules.default];

  services.restic-backup-service = {
    enable = true;
    backupTime = "06:30";
    backupPaths = backupPaths;
    secretKeyFile = "/run/secrets/resticENV";
  };
}
