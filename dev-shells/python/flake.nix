{
  description = "A Nix-flake-based Python development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    version = "3.13";
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.python3
        pkgs.python3Packages.pip
        pkgs.python3Packages.virtualenv
      ];
    };
  };
}

