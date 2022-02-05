{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/a529f0c125a78343b145a8eb2b915b0295e4f459.tar.gz") { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    libp11
    opensc
    openssl
    yubikey-manager
    yubico-piv-tool
  ];
  shellHook = ''
    export SO_PATH="${pkgs.libp11}/lib/engines/pkcs11.dylib"
    export MODULE_PATH="${pkgs.opensc}/lib/opensc-pkcs11.so"
  '';
}
