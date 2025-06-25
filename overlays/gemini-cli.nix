final: prev: {
  gemini-cli = prev.buildNpmPackage {
    pname = "gemini-cli";
    version = "0.1.1";

    src = prev.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "52afcb3a1233237b07aa86b1678f4c4eded70800";
      hash = "sha256-KNnfo5hntQjvc377A39+QBemeJjMVDRnNuGY/93n3zc=";
    };

    npmDepsHash = "sha256-/IAEcbER5cr6/9BFZYuV2j1jgA75eeFxaLXdh1T3bMA=";

    npmBuild = "npm run build";
    dontNpmPrune = true;

    postInstall = ''
      # The symlinks expect a `packages` directory in the root of the installation
      # Copy it from the source to the destination to make the links valid.
      cp -r packages $out/lib/node_modules/@google/gemini-cli"/
    '';
  };
}
# To get the hashes use: nix-prefetch-git https://github.com/google-gemini/gemini-cli.git --rev early-access
# To use gemini-cli, type: gemini into the terminal.
# You can remove this overlay once gemini-cli is available in the official Nixpkgs repository.

