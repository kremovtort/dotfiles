{ pkgs, flake-self, config, ... }:
{
  home.packages = [
    pkgs.age
    pkgs.sops
    pkgs.ssh-to-age
  ];

  sops = {
    defaultSopsFile = "${flake-self}/secrets/secrets.yaml";
    
    # Use SSH key as age key source
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    
    secrets.openrouter-api-key = {};
    secrets.context7-api-key = {};
  };
}
