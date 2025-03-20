switch:
    if [ "$(uname)" = "Darwin" ]; then darwin-rebuild switch --flake .; fi
    home-manager switch --flake .

upgrade:
    nix flake update --flake .
    just switch
    if [ "$(uname)" = "Darwin" ]; then brew upgrade; fi