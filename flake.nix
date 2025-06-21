{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05"; # Stable channel for everything else
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; # Unstable channel
    nixos-wsl.url = "github:nix-community/NixOS-WSL"; # NixOS WSL
    nixpkgs-oldvscode.url = "github:NixOS/nixpkgs/333d19c8b58402b94834ec7e0b58d83c0a0ba658"; # vscode 1.98.2
    flatpaks.url = "github:GermanBread/declarative-flatpak/stable-v3";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

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

  # Optional: Binary cache for the flake
  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
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
    nixos-raspberrypi,
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
        specialArgs = {inherit disks inputs system home-manager self nixos-raspberrypi;};
        modules = [
          disko.nixosModules.disko
          flatpaks.nixosModule
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
    nixosConfigurations = {
      tim-laptop = self.mkSystem {
        hostFile = ./hosts/tim-laptop.nix;
        system = "x86_64-linux";
        disks = ["/dev/nvme0n1"];
      };
      tim-pc = self.mkSystem {
        hostFile = ./hosts/tim-pc.nix;
        system = "x86_64-linux";
        disks = ["/dev/nvme0n1" "/dev/nvme1n1"];
      };
      tim-server = self.mkSystem {
        # nix run nixpkgs#nixos-anywhere -- --flake ./#tim-server root@142.132.234.128
        hostFile = ./hosts/tim-server.nix;
        system = "x86_64-linux";
        disks = ["/dev/sda"];
      };
      tim-wsl = self.mkSystem {
        hostFile = ./hosts/tim-wsl.nix;
        system = "x86_64-linux";
      };
      homeassistant-yellow = self.mkSystem {
        hostFile = ./hosts/homeassistant-yellow.nix;
        # Runs on a Raspberry Pi Compute Module 5 Arm64
        system = "aarch64-linux";
        disks = ["/dev/nvme0n1"];
      };
      tim-pi4 = self.mkSystem {
        hostFile = ./hosts/rpi4.nix;
        system = "aarch64-linux";
      };
      tim-pi5 = self.mkSystem {
        hostFile = ./hosts/rpi5.nix;
        system = "aarch64-linux";
      };

      # Single installer that carries install scripts for every host
      installer = let
        system = "x86_64-linux";
        pkgs = import nixpkgs-stable {inherit system;};
        home-manager = inputs.home-manager;
        hosts = ["tim-laptop" "tim-pc" "tim-server"];
        hostDisks = {
          "tim-laptop" = ["/dev/nvme0n1"];
          "tim-pc" = ["/dev/nvme0n1" "/dev/nvme1n1"];
          "tim-server" = ["/dev/sda"];
        };
      in
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self inputs hosts hostDisks home-manager;
          };
          modules = [
            disko.nixosModules.disko
            vscode-server.nixosModules.default
            ({
              pkgs,
              lib,
              inputs,
              ...
            }: {
              imports = [
                (import ./common/installer.nix {
                  inherit pkgs self lib hosts hostDisks home-manager;
                })
              ];
            })
          ];
        };

      installer-arm = let
        system = "aarch64-linux";
        pkgs = import nixpkgs-stable {inherit system;};
        home-manager = inputs.home-manager;
        hosts = ["homeassistant-yellow"];
        hostDisks = {
          "homeassistant-yellow" = ["/dev/nvme0n1"];
        };
      in
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self inputs hosts hostDisks home-manager;
          };
          modules = [
            disko.nixosModules.disko
            vscode-server.nixosModules.default
            ({
              pkgs,
              lib,
              inputs,
              ...
            }: {
              imports = with nixos-raspberrypi.nixosModules; [
                # Required: Add necessary overlays with kernel, firmware, vendor packages
                nixos-raspberrypi.lib.inject-overlays

                # Binary cache with prebuilt packages for the currently locked `nixpkgs`,
                # see `devshells/nix-build-to-cachix.nix` for a list
                trusted-nix-caches

                # Optional: All RPi and RPi-optimised packages to be available in `pkgs.rpi`
                nixpkgs-rpi

                # Optonal: add overlays with optimised packages into the global scope
                # provides: ffmpeg_{4,6,7}, kodi, libcamera, vlc, etc.
                # This overlay may cause lots of rebuilds (however many
                #  packages should be available from the binary cache)
                nixos-raspberrypi.lib.inject-overlays-global

                (import ./common/installer.nix {
                  inherit pkgs self lib hosts hostDisks home-manager;
                })
              ];

              boot.kernelPackages = pkgs.linuxPackages_rpi5;
            })
          ];
        };
    };
  };
}
