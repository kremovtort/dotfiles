{
  agents,
  agentsInputs,
  config,
  lib,
  ...
}:
{
  home.activation.copyCursorAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cursorAgentsDir="${config.home.homeDirectory}/.cursor/agents"
    mkdir -p "$cursorAgentsDir"

    # Replace any existing symlinks with regular files.
    rm -f \
      "$cursorAgentsDir/designer.md" \
      "$cursorAgentsDir/fixer.md" \
      "$cursorAgentsDir/librarian.md" \
      "$cursorAgentsDir/oracle.md"

    cp -f "${agents}/cursor/agents/designer.md" "$cursorAgentsDir/designer.md"
    cp -f "${agents}/cursor/agents/fixer.md" "$cursorAgentsDir/fixer.md"
    cp -f "${agents}/cursor/agents/librarian.md" "$cursorAgentsDir/librarian.md"
    cp -f "${agents}/cursor/agents/oracle.md" "$cursorAgentsDir/oracle.md"
  '';

  home.file = {
    ".cursor/commands/rmslop.md".source = "${agents}/commands/rmslop.md";
    ".cursor/commands/spellcheck.md".source = "${agents}/commands/spellcheck.md";

    ".cursor/skills/vcs-detect".source = "${agents}/skills/vcs-detect";
    ".cursor/skills/jujutsu".source = "${agents}/skills/jujutsu";
    ".cursor/skills/ast-grep".source = "${agentsInputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep";
    ".cursor/skills/skill-creator".source = "${agentsInputs.anthropicSkills}/skills/skill-creator";
  };
}
