{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable-v3";
    disko.url = "github:nix-community/disko";
    comin.url = "github:nlewo/comin";
    sops-nix.url = "github:Mic92/sops-nix";

    morewaita = {
      url = "github:somepaulo/MoreWaita";
      flake = false;
    };
    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flatpaks, disko, comin, sops-nix, firefox-gnome-theme, morewaita, ... }@attrs: {
    nixosConfigurations.tim-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ 
        disko.nixosModules.disko
        flatpaks.nixosModules.default
        comin.nixosModules.comin
        sops-nix.nixosModules.sops
        (import ./install.nix { disks = [ "/dev/nvme0n1" ]; }) # Edit this if hardware changed in the future
        ./hosts/tim-laptop.nix 
      ];
    };
  };
}
