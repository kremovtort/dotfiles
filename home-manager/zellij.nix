{ pkgs }:
{
  enable = true;
  settings = {
    theme = "catppuccin-mocha";
    scroll_buffer_size = 50000;
    show_startup_tips = false;
    default_mode = "locked";
    mouse_mode = true;
    copy_command = "pbcopy";
    copy_on_select = true;
    scrollback_editor = "nvim";
  };

  extraConfig = ''
    keybinds clear-defaults=true {
        // Locked mode - default mode, Ctrl+Space to enter tmux mode
        locked {
            bind "Ctrl Space" { SwitchToMode "Tmux"; }
        }

        // Tmux mode - similar to tmux prefix behavior
        // Each binding returns to Locked mode after action (auto-exit)
        tmux {
            bind "Esc" { SwitchToMode "Locked"; }
            bind "Ctrl Space" { SwitchToMode "Locked"; }

            // Splits like tmux: - for horizontal, | for vertical
            bind "-" { NewPane "Down"; SwitchToMode "Locked"; }
            bind "|" { NewPane "Right"; SwitchToMode "Locked"; }

            // Pane navigation with hjkl (like tmux with vi mode)
            bind "h" { MoveFocus "Left"; SwitchToMode "Locked"; }
            bind "j" { MoveFocus "Down"; SwitchToMode "Locked"; }
            bind "k" { MoveFocus "Up"; SwitchToMode "Locked"; }
            bind "l" { MoveFocus "Right"; SwitchToMode "Locked"; }

            // Pane resize (stay in tmux mode for continuous resize)
            bind "H" { Resize "Increase Left"; }
            bind "J" { Resize "Increase Down"; }
            bind "K" { Resize "Increase Up"; }
            bind "L" { Resize "Increase Right"; }

            // Tab management (baseIndex = 1 equivalent)
            bind "c" { NewTab; SwitchToMode "Locked"; }
            bind "1" { GoToTab 1; SwitchToMode "Locked"; }
            bind "2" { GoToTab 2; SwitchToMode "Locked"; }
            bind "3" { GoToTab 3; SwitchToMode "Locked"; }
            bind "4" { GoToTab 4; SwitchToMode "Locked"; }
            bind "5" { GoToTab 5; SwitchToMode "Locked"; }
            bind "6" { GoToTab 6; SwitchToMode "Locked"; }
            bind "7" { GoToTab 7; SwitchToMode "Locked"; }
            bind "8" { GoToTab 8; SwitchToMode "Locked"; }
            bind "9" { GoToTab 9; SwitchToMode "Locked"; }
            bind "n" { GoToNextTab; SwitchToMode "Locked"; }
            bind "p" { GoToPreviousTab; SwitchToMode "Locked"; }

            // Close pane/tab
            bind "x" { CloseFocus; SwitchToMode "Locked"; }
            bind "X" { CloseTab; SwitchToMode "Locked"; }

            // Zoom pane (like tmux z)
            bind "z" { ToggleFocusFullscreen; SwitchToMode "Locked"; }

            // Detach (like tmux d)
            bind "d" { Detach; }

            // Enter scroll/copy mode (like tmux [)
            bind "[" { SwitchToMode "Scroll"; }

            // Rename tab
            bind "," { SwitchToMode "RenameTab"; }

            // Session management
            bind "s" { SwitchToMode "Session"; }
        }

        // Scroll mode with vi-like bindings
        scroll {
            bind "Esc" { SwitchToMode "Locked"; }
            bind "Ctrl c" { SwitchToMode "Locked"; }
            bind "q" { SwitchToMode "Locked"; }
            
            // Vi navigation
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Ctrl f" "PageDown" { PageScrollDown; }
            bind "Ctrl b" "PageUp" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "g" { ScrollToTop; }
            bind "G" { ScrollToBottom; }
            
            // Search
            bind "/" { SwitchToMode "EnterSearch"; Search "down"; }
            bind "?" { SwitchToMode "EnterSearch"; Search "up"; }
        }

        // Search mode
        search {
            bind "Esc" { SwitchToMode "Locked"; }
            bind "Ctrl c" { SwitchToMode "Locked"; }
            bind "q" { SwitchToMode "Locked"; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Ctrl f" "PageDown" { PageScrollDown; }
            bind "Ctrl b" "PageUp" { PageScrollUp; }
        }

        entersearch {
            bind "Esc" { SwitchToMode "Scroll"; }
            bind "Ctrl c" { SwitchToMode "Locked"; }
            bind "Enter" { SwitchToMode "Search"; }
        }

        // Rename tab mode
        renametab {
            bind "Esc" { UndoRenameTab; SwitchToMode "Locked"; }
            bind "Enter" { SwitchToMode "Locked"; }
        }

        // Session mode
        session {
            bind "Esc" { SwitchToMode "Locked"; }
            bind "d" { Detach; }
        }
    }

    // Plugins
    load_plugins {
        "file:${pkgs.zjstatus}/bin/zjframes.wasm" {
            hide_frame_for_single_pane       "false"
            hide_frame_except_for_search     "false"
            hide_frame_except_for_scroll     "false"
            hide_frame_except_for_fullscreen "false"
        }
    }
  '';

  layouts.default = ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
                    format_left   "{mode} #[fg=#89B4FA,bold]{session}"
                    format_center "{tabs}"
                    format_right  "{command_git_branch} {datetime}"
                    format_space  ""

                    border_enabled  "false"
                    border_char     "─"
                    border_format   "#[fg=#6C7086]{char}"
                    border_position "top"

                    hide_frame_for_single_pane "true"

                    mode_normal  "#[bg=blue] "
                    mode_tmux    "#[bg=#ffc387] "

                    tab_normal   "#[fg=#6C7086] {name} "
                    tab_active   "#[fg=#9399B2,bold,italic] {name} "

                    command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                    command_git_branch_format      "#[fg=blue] {stdout} "
                    command_git_branch_interval    "10"
                    command_git_branch_rendermode  "static"

                    datetime        "#[fg=#6C7086,bold] {format} "
                    datetime_format "%A, %d %b %Y %H:%M"
                    datetime_timezone "Europe/Berlin"
                }
            }
        }
    }
  '';
}

