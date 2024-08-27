{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable-v3";
    disko.url = "github:nix-community/disko";
  };

  outputs = { self, nixpkgs, flatpaks, disko, ... }@attrs: {
    nixosConfigurations.tim-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ 
        disko.nixosModules.disko
        flatpaks.nixosModules.default
        (import ./install.nix { disks = [ "/dev/nvme0n1" ]; }) # Edit this if hardware changed in the future
        ./hosts/tim-laptop.nix 
      ];
    };
  };
}
