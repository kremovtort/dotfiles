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

    # Cursor does not reliably pick up subagents when they are symlinked
    # from the Nix store (home.file). Install them as regular files.
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

  home.activation.copyCursorSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cursorSkillsDir="${config.home.homeDirectory}/.cursor/skills"
    mkdir -p "$cursorSkillsDir"

    # Cursor does not reliably pick up skills when they are symlinked
    # from the Nix store (home.file). Install them as regular directories.
    # Replace any existing symlinks/directories with regular directories.
    rm -rf \
      "$cursorSkillsDir/vcs-detect" \
      "$cursorSkillsDir/jujutsu" \
      "$cursorSkillsDir/ast-grep" \
      "$cursorSkillsDir/skill-creator"

    cp -R "${agents}/skills/vcs-detect" "$cursorSkillsDir/vcs-detect"
    cp -R "${agents}/skills/jujutsu" "$cursorSkillsDir/jujutsu"
    cp -R "${agentsInputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep" "$cursorSkillsDir/ast-grep"
    cp -R "${agentsInputs.anthropicSkills}/skills/skill-creator" "$cursorSkillsDir/skill-creator"
  '';

  home.file = {
    ".cursor/commands/rmslop.md".source = "${agents}/commands/rmslop.md";
    ".cursor/commands/spellcheck.md".source = "${agents}/commands/spellcheck.md";
  };
}
