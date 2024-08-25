{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable-v3";
    disko.url = "github:nix-community/disko"; # Adding disko as an input
  };

  outputs = { self, nixpkgs, flatpaks, disko, ... }@attrs: {
    nixosConfigurations.tim-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ 
        flatpaks.nixosModules.default
        ./hosts/tim-laptop.nix 
      ];
    };

    nixosConfigurations.install = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        disko.nixosModules.disko
        ./install.nix
      ];

      # You can specify disks during installation here or pass them from the CLI
      # For example, during installation:
      # `nixos-install --flake .#install --arg disks '[ "/dev/nvme0n1", "/dev/nvme1n1" ]'`
      configuration = {
        disks = [ "/dev/nvme0n1", "/dev/nvme1n1" ];
      };
    };
  };
}
