.PHONY: check update

check:
	sudo find /etc/nixos -mindepth 1 -maxdepth 1 ! -name "flake.lock" -exec rm -rf {} +
	sudo cp -a ~/Coding/nixos/. /etc/nixos/
	sudo nixos-rebuild dry-run --flake /etc/nixos#$$(cat /etc/hostname)
	nix build /etc/nixos#nixosConfigurations.$$(cat /etc/hostname).config.home-manager.users.tim.home.activationPackage --dry-run

update:
	nix flake update ~/Coding/nixos
