{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    
    flatpaks = {
      url = "github:GermanBread/declarative-flatpak/stable-v3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    morewaita = {
      url = "github:somepaulo/MoreWaita";
      flake = false;
    };
    
    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flatpaks, disko, comin, sops-nix, vscode-server, home-manager, firefox-gnome-theme, morewaita, ... }: {
    nixosConfigurations.tim-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [ 
        disko.nixosModules.disko
        flatpaks.nixosModules.default
        comin.nixosModules.comin
        # sops-nix.nixosModules.sops
        vscode-server.nixosModules.default
        (import ./install.nix { disks = [ "/dev/nvme0n1" ]; }) # Edit this if hardware changed in the future
        ./hosts/tim-laptop.nix 
      ];
    };
  };
}
