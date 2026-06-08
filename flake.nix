{
  description = "NixOS from Scratch";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    frc-nix = {
      url = "github:frc4451/frc-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.agenix.inputs.darwin.follows = "";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, agenix, home-manager, ... }:
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
          agenix.nixosModules.default
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

      mark-ltw-l = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          overlays = import ./overlays { inherit inputs; };
          inherit self inputs;
        };
        modules = [
          ({ pkgs, ... }: {
            # Mark securecrt and unstable available
            nixpkgs.overlays = import ./overlays { inherit inputs; };
          })
          agenix.nixosModules.default
          ./machines/mark-ltw-l
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.schne112 = import ./machines/mark-ltw-l/home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };

      # Other hosts here
    };
    templates = import ./dev-shells;
  };
}
