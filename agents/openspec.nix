{ agentsInputs, ... }:
let
  schemasRoot = agentsInputs.openspecSchemas + "/openspec/schemas";
in
{
  # OpenSpec 1.3.x resolves user schemas from the XDG data directory:
  # ${XDG_DATA_HOME:-~/.local/share}/openspec/schemas.
  # Use recursive linking so schema entries are real directories; the CLI lists
  # schemas via Dirent.isDirectory(), which ignores directory symlinks.
  xdg.dataFile."openspec/schemas" = {
    source = schemasRoot;
    recursive = true;
  };
}
