.PHONY: check

check:
	sudo find /etc/nixos -mindepth 1 -maxdepth 1 ! -name "flake.lock" -exec rm -rf {} +
	sudo cp -a ~/Coding/nixos/. /etc/nixos/
	sudo nixos-rebuild dry-run --flake /etc/nixos#$$(cat /etc/hostname)
