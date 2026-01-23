{ inputs, self }:
{ ... }:
{
  _module.args.agentsInputs = inputs;
  _module.args.agents = self;
  imports = [
    ./cursor.nix
    ./opencode.nix
  ];
}
