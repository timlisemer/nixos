.PHONY: check update

check:
	alejandra .

update:
	nix flake update ~/Coding/nixos
