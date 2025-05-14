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

[macos]
run-nix-builder:
    mkdir -p keys && ssh-keygen -t ed25519 -f keys/client-key -N ""
    docker run -d --name nix-builder -p 3022:22 \
        -v $PWD/keys/client-key.pub:/etc/ssh/authorized_keys.d/client \
        nixos/nix sleep infinity