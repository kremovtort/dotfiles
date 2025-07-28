[linux]
switch:
    home-manager switch --flake .

[macos]
switch TARGET:
    #!/usr/bin/env bash
    if [[ -z "{{TARGET}}" ]]; then
      sudo darwin-rebuild switch --flake .
      home-manager switch --flake .
    elif [[ "{{TARGET}}" == "home" ]]; then
      home-manager switch --flake .
    elif [[ "{{TARGET}}" == "darwin" ]]; then
      sudo darwin-rebuild switch --flake .
    fi
    
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
