[macos]
darwin-rebuild-switch:
  sudo nix run .#darwin-rebuild -- switch --flake .

home-manager-switch:
  nix run .#home-manager -- switch --flake .

[linux]
switch: setup-shell home-manager-switch

[macos]
switch TARGET="":
  #!/usr/bin/env bash
  just setup-shell
  if [[ -z "{{TARGET}}" ]]; then
    just darwin-rebuild-switch
    just home-manager-switch
  elif [[ "{{TARGET}}" == "home" ]]; then
    just home-manager-switch
  elif [[ "{{TARGET}}" == "darwin" ]]; then
    just darwin-rebuild-switch
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

configure-nvim:
  XDG_CONFIG_HOME=$(realpath "$(dirname "$0")") NVIM_APPNAME=lazyvim nvim

setup-shell:
  #!/usr/bin/env sh
  if [ ! -d "/etc/nixos" ] && [ "$(uname)" != "Darwin" ]; then
    if ! grep -qx "${HOME}/.nix-profile/bin/zsh" /etc/shells; then
      echo "${HOME}/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
    fi
    sudo chsh -s "${HOME}/.nix-profile/bin/zsh" "${USER}"
  fi
