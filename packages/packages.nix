{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./flatpaks.nix
    ./applications.nix
    ./system-packages.nix
    ./vscode.nix
    ./dependencies.nix
    ./firefox.nix
  ];
}
