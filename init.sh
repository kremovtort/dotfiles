#!/usr/bin/env sh

if ! command -v nix >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm 
fi

nix develop --command sh -c "just switch"