{
  pkgs ? import <nixpkgs> { },
}:

{
  brave-nightly = pkgs.callPackage ./pkgs/brave-nightly { };
  rosec = pkgs.callPackage ./pkgs/rosec { };
}
