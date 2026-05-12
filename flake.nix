{
  description = "My personal nix repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      overlays.default = final: prev: {
        ftrepo = import ./default.nix { pkgs = final; };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          packages = import ./default.nix { inherit pkgs; };
        in
        packages
      );
    };
}
