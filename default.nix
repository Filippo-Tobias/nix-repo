{
  pkgs ? import <nixpkgs> { },
}:

{
  brave-nightly = pkgs.callPackage ./pkgs/brave-nightly { };
}
