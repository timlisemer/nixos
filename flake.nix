{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05"; # Stable channel for everything else
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; # Unstable channel
    nixos-wsl.url = "github:nix-community/NixOS-WSL"; # NixOS WSL
    nixpkgs-oldvscode.url = "github:NixOS/nixpkgs/333d19c8b58402b94834ec7e0b58d83c0a0ba658"; # vscode 1.98.2
    # nixpkgs-stable.follows = "nixos-cosmic/nixpkgs-stable";
    # nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";

    flatpaks = {
      url = "github:GermanBread/declarative-flatpak/stable-v3";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    alejandra = {
      # Nix formatter -> https://drakerossman.com/blog/overview-of-nix-formatters-ecosystem
      url = "github:kamadorueda/alejandra/4.0.0";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };

    tim-nvim = {
      url = "github:timlisemer/nvim";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs-stable,
    nixpkgs-unstable,
    nixpkgs-oldvscode,
    flatpaks,
    disko,
    alejandra,
    comin,
    sops-nix,
    vscode-server,
    home-manager,
    rust-overlay,
    firefox-gnome-theme,
    nixos-wsl,
    tim-nvim,
    ...
  }: {
    # Function to create configuration for any host
    mkSystem = hostFile: let
      system = "x86_64-linux";
    in
      nixpkgs-stable.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs system;};
        modules = [
          disko.nixosModules.disko
          flatpaks.nixosModules.declarative-flatpak
          comin.nixosModules.comin
          # sops-nix.nixosModules.sops

          #{
          #  nix.settings = {
          #    substituters = [ "https://cosmic.cachix.org/" ];
          #    trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
          #  };
          #}
          #nixos-cosmic.nixosModules.default

          vscode-server.nixosModules.default

          ({
            pkgs,
            lib,
            inputs,
            ...
          }: {
            environment.variables.NIX_PATH = lib.mkForce "nixpkgs=${inputs.nixpkgs-stable.outPath}";

            nixpkgs.overlays = [
              rust-overlay.overlays.default
            ];
          })

          # Include the specific host configuration
          (import hostFile)
        ];
      };

    # Configurations for tim-laptop and tim-pc
    nixosConfigurations.tim-laptop = self.mkSystem ./hosts/tim-laptop.nix;
    nixosConfigurations.tim-pc = self.mkSystem ./hosts/tim-pc.nix;
    nixosConfigurations.tim-wsl = self.mkSystem ./hosts/tim-wsl.nix;
  };
}
