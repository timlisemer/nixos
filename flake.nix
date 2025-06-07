{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05"; # Stable channel for everything else
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; # Unstable channel
    nixos-wsl.url = "github:nix-community/NixOS-WSL"; # NixOS WSL
    nixpkgs-oldvscode.url = "github:NixOS/nixpkgs/333d19c8b58402b94834ec7e0b58d83c0a0ba658"; # vscode 1.98.2

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
    sops-nix,
    vscode-server,
    home-manager,
    firefox-gnome-theme,
    nixos-wsl,
    tim-nvim,
    ...
  }: {
    mkSystem = {
      hostFile,
      system,
      disks ? null,
    }:
      nixpkgs-stable.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit disks inputs system self;};
        modules = [
          disko.nixosModules.disko
          flatpaks.nixosModules.declarative-flatpak
          vscode-server.nixosModules.default
          ({
            pkgs,
            lib,
            inputs,
            ...
          }: {
            environment.variables.NIX_PATH = lib.mkForce "nixpkgs=${inputs.nixpkgs-stable.outPath}";
          })
          (import hostFile)
        ];
      };

    # Host Configurations
    nixosConfigurations.tim-laptop = self.mkSystem {
      hostFile = ./hosts/tim-laptop.nix;
      system = "x86_64-linux";
      disks = ["/dev/nvme0n1"];
    };
    nixosConfigurations.tim-pc = self.mkSystem {
      hostFile = ./hosts/tim-pc.nix;
      system = "x86_64-linux";
      disks = ["/dev/nvme0n1" "/dev/nvme1n1"];
    };
    nixosConfigurations.tim-server = self.mkSystem {
      hostFile = ./hosts/tim-server.nix;
      system = "x86_64-linux";
      disks = ["/dev/sda"];
    };
    nixosConfigurations.qemu = self.mkSystem {
      hostFile = ./hosts/qemu.nix;
      system = "x86_64-linux";
      disks = ["/dev/vda"];
    };
    nixosConfigurations.tim-wsl = self.mkSystem {
      hostFile = ./hosts/tim-wsl.nix;
      system = "x86_64-linux";
    };

    # Single installer that carries install scripts for every host
    nixosConfigurations.installer = let
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {inherit system;};
      lib = nixpkgs-stable.lib;
      inputs = self.inputs;
      config = self.nixosConfigurations;
      hosts = ["tim-laptop" "tim-pc" "tim-server" "qemu"];
      hostDisks = {
        "tim-laptop" = ["/dev/nvme0n1"];
        "tim-pc" = ["/dev/nvme0n1" "/dev/nvme1n1"];
        "tim-server" = ["/dev/sda"];
        "qemu" = ["/dev/vda"];
      };
    in
      nixpkgs-stable.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit self inputs hosts hostDisks;
          home-manager = inputs.home-manager;
        };
        modules = [
          disko.nixosModules.disko
          vscode-server.nixosModules.default
          (import ./common/installer.nix {
            inherit pkgs self inputs home-manager lib config hosts hostDisks;
          })
        ];
      };
  };
}
