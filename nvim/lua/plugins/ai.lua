return {
  {
    "yetone/avante.nvim",
    dependencies = {
      "HakonHarnes/img-clip.nvim",
      "MeanderingProgrammer/render-markdown.nvim",
    },
    opts = function(_, opts)
      opts.provider = "openrouter"
      opts.model = "openrouter/qwen/qwen3-max"

      opts.providers = opts.providers or {}
      opts.providers.openrouter = {
        __inherited_from = "openai",
        endpoint = "https://openrouter.ai/api/v1",
        api_key_name = "OPENROUTER_API_KEY",
        model = "qwen/qwen3-max",
      }
      opts.providers.morph = {
        __inherited_from = "openai",
        endpoint = "https://openrouter.ai/api/v1",
        api_key_name = "OPENROUTER_API_KEY",
        model = "morph/morph-v3-fast",
      }

      opts.rules = opts.rules or {}
      opts.rules = {
        project_dir = ".cursor/rules",
      }

      opts.behaviour = opts.behaviour or {}
      opts.behaviour.enable_fastapply = true
      opts.behaviour.auto_approve_tool_permissions = false
    end,
  },
}
