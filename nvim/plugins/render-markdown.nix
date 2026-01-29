{ ... }:
{
  plugins."render-markdown" = {
    enable = true;
    settings = {
      anti_conceal.enabled = false;
      file_types = [
        "markdown"
        "opencode_output"
      ];
    };
  };
}
