{
  description = "NixOS from Scratch";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    frc-nix = {
      url = "github:frc4451/frc-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    {
    nixosConfigurations = {
      nixos-test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          overlays = import ./overlays { inherit inputs; };
          inherit self inputs;
        };
        modules = [
          ({ pkgs, ... }: {
            # Make securecrt and unstable available"
            nixpkgs.overlays = import ./overlays { inherit inputs; };
          })
          ./machines/nixos-test
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.xanawatt = import ./machines/nixos-test/home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };

      # Other hosts here
    };
  };
}
