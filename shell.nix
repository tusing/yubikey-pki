{ pkgs ? import <nixpkgs> { } }:
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
