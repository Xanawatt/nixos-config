{ inputs }:

[
  (
    final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = final.stdenv.hostPlatform.system;

        config.allowUnfree = true;
      };
    }
  )

  (
    final: prev: {
      securecrt = prev.callPackage ../common/securecrt.nix { };
    }
  )
]
