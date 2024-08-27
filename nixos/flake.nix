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

    nixosConfigurations.install-tim-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        # Install (Disko) Modules
        disko.nixosModules.disko
        (import ./install.nix { disks = [ "/dev/nvme0n1" ]; }) # Edit this if hardware changed in the future


        # Tim-Laptop Modules
        flatpaks.nixosModules.default
        ./hosts/tim-laptop.nix 
      ];
    };
  };
}
