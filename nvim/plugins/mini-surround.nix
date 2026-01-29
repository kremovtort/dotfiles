{ ... }:
{
  plugins."mini-surround" = {
    enable = true;
    autoLoad = true;
    settings = {
      mappings = {
        add = "gza";
        delete = "gzd";
        find = "gzf";
        find_left = "gzF";
        highlight = "gzh";
        replace = "gzr";
        update_n_lines = "gzn";
      };
    };
  };
}
