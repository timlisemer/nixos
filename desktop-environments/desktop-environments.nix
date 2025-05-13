{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./gnome.nix
    # ./cosmic.nix
  ];
}
