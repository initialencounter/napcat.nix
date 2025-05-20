{
  outputs = {
    self, nixpkgs, flake-utils,
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
  in rec {
    packages.default = pkgs.callPackage ./package.nix {};
    devShells.default = pkgs.mkShell {
      buildInputs = [
        self.packages.${system}.default
      ];
    };
  });
}
