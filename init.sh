#!/usr/bin/env sh
set -e

cd "$(dirname "$0")"

if ! command -v nix >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm 
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

nix develop --command sh -c "just switch"

if [ ! -d "/etc/nixos" ] && [ "$(uname)" != "Darwin" ]; then
    echo "${HOME}/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
    sudo chsh -s "${HOME}/.nix-profile/bin/zsh" kremovtort
fi