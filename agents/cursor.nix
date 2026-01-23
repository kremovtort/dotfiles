{ agents, agentsInputs, ... }:
{
  home.file = {
    ".cursor/commands/rmslop.md".source = "${agents}/commands/rmslop.md";
    ".cursor/commands/spellcheck.md".source = "${agents}/commands/spellcheck.md";

    ".cursor/skills/vcs-detect".source = "${agents}/skills/vcs-detect";
    ".cursor/skills/jujutsu".source = "${agents}/skills/jujutsu";
    ".cursor/skills/ast-grep".source = "${agentsInputs.astGrepClaudeSkill}/ast-grep/skills/ast-grep";
    ".cursor/skills/skill-creator".source = "${agentsInputs.anthropicSkills}/skills/skill-creator";

    ".cursor/agents/designer.md".source = "${agents}/cursor/agents/designer.md";
    ".cursor/agents/fixer.md".source = "${agents}/cursor/agents/fixer.md";
    ".cursor/agents/librarian.md".source = "${agents}/cursor/agents/librarian.md";
    ".cursor/agents/oracle.md".source = "${agents}/cursor/agents/oracle.md";
  };
}
