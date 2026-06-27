{
  pkgs,
  inputs,
  system,
  ...
}:
let
  herdr = inputs.llm-agents.packages.${system}.herdr;
  herdrWrapper = pkgs.writeShellScriptBin "herdr" ''
    set -euo pipefail

    if [[ "''${1:-}" != "remote-client-bridge" ]]; then
      exec ${herdr}/bin/herdr "$@"
    fi

    session="default"
    args=("$@")
    for ((i = 1; i < ''${#args[@]}; i++)); do
      if [[ "''${args[$i]}" == "--session" && $((i + 1)) -lt ''${#args[@]} ]]; then
        session="''${args[$((i + 1))]}"
        break
      fi
    done

    sock_dir="$HOME/.ssh/herdr-agent"
    sock="$sock_dir/$session.sock"
    ${pkgs.coreutils}/bin/mkdir -p "$sock_dir"
    ${pkgs.coreutils}/bin/ln -sfn "$SSH_AUTH_SOCK" "$sock"

    SSH_AUTH_SOCK="$sock" exec ${herdr}/bin/herdr "$@"
  '';
in
{
  home.packages = [
    herdrWrapper
  ];
}
