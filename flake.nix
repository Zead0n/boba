{
  description = "Development flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      mapSystems = f: lib.genAttrs systems (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      devShells = mapSystems (
        { pkgs }:
        with pkgs;
        {
          default = mkShell {
            packages = [
              luau-lsp
              rojo
              stylua
              selene
              wally
            ];
          };
        }
      );
    };
}
