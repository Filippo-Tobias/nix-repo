{
  pkgs ? import <nixpkgs> { },
}:

{
  brave-nightly = pkgs.callPackage ./pkgs/brave-nightly { };
  rosec = pkgs.callPackage ./pkgs/rosec { };
  wlr-shot = pkgs.callPackage ./pkgs/wlr-shot { };
}
