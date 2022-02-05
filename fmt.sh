#!/usr/bin/env bash
set -eou pipefail

# Run me with
# "nix-shell fmt.nix --run :"

argbash -i root.sh
shfmt -w .
nixpkgs-fmt .
