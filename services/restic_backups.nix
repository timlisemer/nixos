{
  config,
  pkgs,
  lib,
  backupPaths,
  hostName,
  inputs,
  ...
}: {
  imports = [inputs.restic-backup-service.nixosModules.default];

  services.restic-backup-service = {
    enable = true;
    backupTime = "06:30";
    backupPaths = backupPaths;
    secret_file_path = "/run/secrets/resticENV";
    exclude.patterns = [
      "*.v3"
      "*.hoi4"
      "**/node_modules/**"
      "**/.cache/**"
      "**/.cargo/**"
      "**/target/debug/**"
      "**/target/release/**"
    ];
  };
}
