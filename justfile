[linux]
switch:
    home-manager switch --flake .

[macos]
switch:
    darwin-rebuild switch --flake .
    home-manager switch --flake .
    
[linux]
upgrade:
    nix flake update --flake .
    just switch

[macos]
upgrade:
    nix flake update --flake .
    just switch
    brew update
    brew upgrade
    brew upgrade --cask --greedy --force