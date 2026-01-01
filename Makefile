.PHONY: check update

check:
	alejandra --check .

update:
	nix flake update ~/Coding/nixos
