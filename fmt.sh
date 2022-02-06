#!/usr/bin/env bash
set -eou pipefail

# Run me with
# "nix-shell fmt.nix --run :"

for sh in endpoint.sh root.sh; do
	argbash -i $sh >/dev/null 2>&1
done

for sh in *.sh; do
	shfmt -w $sh >/dev/null 2>&1
done

gomplate -f fmt.md -o README.md

nixpkgs-fmt . >/dev/null 2>&1
