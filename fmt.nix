# Simply run "nix-shell fmt.nix --run :"

{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/a529f0c125a78343b145a8eb2b915b0295e4f459.tar.gz") { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    shfmt
    argbash
    nixpkgs-fmt
  ];
  shellHook = ''
    ./fmt.sh
  '';
}
