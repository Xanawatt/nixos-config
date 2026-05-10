{
  description = "NixOS from Scratch";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nikpkgs-unsable.url = "github:nixos/nixpkgs/nixos-unstable";
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
    let
      pkgs-overlay = final: prev: {
        securecrt = prev.callPackage ./common/securecrt.nix { };
      };
    in
    {
    nixosConfigurations.nixos-test = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ({ config, pkgs, ... }: {
          # Make securecrt available"
          nixpkgs.overlays = [ pkgs-overlay ];
        }) 
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.xanawatt = import ./home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}
