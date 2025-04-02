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
    brew upgrade --cask

[linux]
[macos]
configure-nvim:
  XDG_CONFIG_HOME=$(realpath "$(dirname "$0")") NVIM_APPNAME=lazyvim nvim
