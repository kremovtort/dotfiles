{ ... }:
{
  plugins.origami = {
    enable = true;
    autoLoad = true;

    settings = {
      useLspFoldsWithTreesitterFallback = {
        enabled = true;
        foldmethodIfNeitherIsAvailable = "indent";
      };

      pauseFoldsOnSearch = true;

      foldtext = {
        enabled = true;
        padding.width = 3;

        lineCount = {
          template = "%d lines";
          hlgroup = "Comment";
        };

        diagnosticsCount = true;
        gitsignsCount = false;
        disableOnFt = [ "snacks_picker_input" ];
      };

      autoFold = {
        enabled = true;
        kinds = [
          "comment"
          "imports"
        ];
      };

      foldKeymaps = {
        setup = true;
        closeOnlyOnFirstColumn = false;
        scrollLeftOnCaret = false;
      };
    };
  };
}
