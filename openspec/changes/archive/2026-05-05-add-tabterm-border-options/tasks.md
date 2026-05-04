## 1. Border Configuration

- [x] 1.1 Update tabterm config annotations to document `single`, `double`, `round`, and `none` border values.
- [x] 1.2 Update border normalization to accept only the supported string values while preserving `true -> single`, `false -> none`, and default behavior.
- [x] 1.3 Ensure unknown border strings fall back to the default `single` style.

## 2. Borderless UI Styling

- [x] 2.1 Add tabterm-owned role-based highlight mappings for sidebar and panel backgrounds.
- [x] 2.2 Apply the sidebar `TabtermSidebar` and panel `TabtermPanel` split only when `ui.border = "none"`.
- [x] 2.3 Ensure bordered layouts use the same `TabtermPanel` effective floating background mapping for sidebar and panel.
- [x] 2.4 Add one column of left padding to the panel only when `ui.border = "none"`.

## 3. Verification

- [x] 3.1 Verify `single`, `double`, and `round` border styles render on both sidebar and panel windows.
- [x] 3.2 Verify `none` renders without float borders, without reserved border spacing between sidebar and panel, and with one column of panel left padding.
- [x] 3.3 Verify borderless sidebar and panel backgrounds are role-based and do not swap when focus changes.
- [x] 3.4 Run the relevant formatter/check command for the touched Lua/Nix files.
