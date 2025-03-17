switch:
    darwin-rebuild switch --flake .
    home-manager switch --flake .

upgrade:
    nix flake update --flake .
    brew upgrade
    just switch