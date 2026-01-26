{
  agents,
  agentsInputs,
  config,
  lib,
  ...
}:
let
  localAgent = name: {
    inherit name;
    src = "${agents}/cursor/agents/${name}.md";
  };
  cursorAgents = [
    (localAgent "scout")
    (localAgent "runner")
    (localAgent "docs-digger")
  ];

  localSkill = name: {
    inherit name;
    src = "${agents}/skills/${name}";
  };
  cursorSkills = [
    (localSkill "vcs-detect")
    (localSkill "jujutsu")
    {
      name = "ast-grep";
      src = "${agentsInputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep";
    }
    {
      name = "skill-creator";
      src = "${agentsInputs.anthropicSkills}/skills/skill-creator";
    }
  ];

  copyCursorAgent =
    { name, src }:
    ''
      cp -f "${src}" "${cursorAgentsDir}/${name}.md"
      chmod +w "${cursorAgentsDir}/${name}.md"
    '';

  copyCursorSkill =
    { name, src }:
    ''
      cp -R "${src}" "${cursorSkillsDir}"
      chmod -R +w "${cursorSkillsDir}/${name}"
    '';

  localRule = name: {
    inherit name;
    src = "${agents}/cursor/rules/${name}.mdc";
  };
  cursorRules = [
    (localRule "agents")
  ];

  copyCursorRule =
    { name, src }:
    ''
      cp -f "${src}" "${cursorRulesDir}/${name}.mdc"
      chmod +w "${cursorRulesDir}/${name}.mdc"
    '';

  cursorAgentsDir = "${config.home.homeDirectory}/.cursor/agents";
  cursorSkillsDir = "${config.home.homeDirectory}/.cursor/skills";
  cursorRulesDir = "${config.home.homeDirectory}/.cursor/rules";
in
{
  # Cursor does not reliably pick up subagents when they are symlinked
  # from the Nix store (home.file). Install them as regular files.
  home.activation.copyCursorAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${cursorAgentsDir}"

    ${lib.concatStringsSep "\n" (map copyCursorAgent cursorAgents)}
  '';

  # Cursor does not reliably pick up skills when they are symlinked
  # from the Nix store (home.file). Install them as regular directories.
  home.activation.copyCursorSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${cursorSkillsDir}"

    ${lib.concatStringsSep "\n" (map copyCursorSkill cursorSkills)}
  '';

  # Cursor user rules live in ~/.cursor/rules. Install as real files.
  home.activation.copyCursorRules = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${cursorRulesDir}"

    ${lib.concatStringsSep "\n" (map copyCursorRule cursorRules)}
  '';

  home.file = {
    ".cursor/commands/rmslop.md".source = "${agents}/commands/rmslop.md";
    ".cursor/commands/spellcheck.md".source = "${agents}/commands/spellcheck.md";
  };
}
