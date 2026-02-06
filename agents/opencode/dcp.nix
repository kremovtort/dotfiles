let
  dcpConfig = {
    turnProtection = {
      enabled = true;
      turns = 10;
    };
    tools.settings.contextLimit = 200000;
  };
in {
  home.file.".config/opencode/dcp.jsonc".text = builtins.toJSON dcpConfig; 

  programs.opencode.settings.plugin = [
    "@tarquinen/opencode-dcp@2.0.0"
  ];
}
