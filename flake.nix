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

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
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

    blesh = {
      url = "https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz";
      flake = false;
    };

    tim-nvim = {
      url = "github:timlisemer/nvim";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flatpaks, disko, comin, sops-nix, vscode-server, home-manager, rust-overlay, firefox-gnome-theme, morewaita, blesh, tim-nvim, ... }: {
    
    # Function to create configuration for any host
    mkSystem = hostFile: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [ 
        disko.nixosModules.disko
        flatpaks.nixosModules.default
        comin.nixosModules.comin
        # sops-nix.nixosModules.sops
        vscode-server.nixosModules.default
        (import ./install.nix { disks = [ "/dev/nvme0n1" ]; }) # Edit this if hardware changed in the future

        ({ pkgs, ... }: {
           nixpkgs.overlays = [ rust-overlay.overlays.default ];
           environment.systemPackages = [ 
             (pkgs.rust-bin.stable.latest.default.overrideAttrs (old: {
               extensions = [ "rustfmt" "clippy" "rust-src" "rustc-dev" "llvm-tools-preview" "cargo" "rust-analyzer" ];
               targets = [ "x86_64-unknown-linux-gnu" ];
             }))
           ];
         })

        # Include the specific host configuration
        (import hostFile)
      ];
    };

    # Configurations for tim-laptop and tim-pc
    nixosConfigurations.tim-laptop = self.mkSystem ./hosts/tim-laptop.nix;
    nixosConfigurations.tim-pc = self.mkSystem ./hosts/tim-pc.nix;
  };
}

