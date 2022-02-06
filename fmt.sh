#!/usr/bin/env bash
set -eou pipefail

# Run me with
# "nix-shell fmt.nix --run :"

nixpkgs-fmt . >/dev/null 2>&1

for sh in endpoint.sh root.sh; do
	argbash -i $sh >/dev/null 2>&1
done

for sh in *.sh; do
	shfmt -w $sh >/dev/null 2>&1
done

export ROOT_USAGE=$(./root.sh --help)
export ENDPOINT_USAGE=$(./endpoint.sh --help)
gomplate -f fmt.md -o README.md
