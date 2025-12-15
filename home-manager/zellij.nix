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

        // Normal mode
        normal {
            bind "Ctrl Space" { SwitchToMode "Tmux"; }
        }

        // Tmux mode - similar to tmux prefix behavior
        // Each binding returns to Normal mode after action (auto-exit)
        tmux {
            bind "Esc" { SwitchToMode "Normal"; }
            bind "Ctrl Space" { SwitchToMode "Normal"; }

            // Splits like tmux: - for horizontal, | for vertical
            bind "-" { NewPane "Down"; SwitchToMode "Normal"; }
            bind "|" { NewPane "Right"; SwitchToMode "Normal"; }

            // Pane navigation with hjkl (like tmux with vi mode)
            bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
            bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
            bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
            bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }

            // Pane resize
            bind "H" { Resize "Increase Left"; }
            bind "J" { Resize "Increase Down"; }
            bind "K" { Resize "Increase Up"; }
            bind "L" { Resize "Increase Right"; }

            // Tab management (baseIndex = 1 equivalent)
            bind "c" { NewTab; SwitchToMode "Normal"; }
            bind "1" { GoToTab 1; SwitchToMode "Normal"; }
            bind "2" { GoToTab 2; SwitchToMode "Normal"; }
            bind "3" { GoToTab 3; SwitchToMode "Normal"; }
            bind "4" { GoToTab 4; SwitchToMode "Normal"; }
            bind "5" { GoToTab 5; SwitchToMode "Normal"; }
            bind "6" { GoToTab 6; SwitchToMode "Normal"; }
            bind "7" { GoToTab 7; SwitchToMode "Normal"; }
            bind "8" { GoToTab 8; SwitchToMode "Normal"; }
            bind "9" { GoToTab 9; SwitchToMode "Normal"; }
            bind "n" { GoToNextTab; SwitchToMode "Normal"; }
            bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }

            // Close pane/tab
            bind "x" { CloseFocus; SwitchToMode "Normal"; }
            bind "X" { CloseTab; SwitchToMode "Normal"; }

            // Zoom pane (like tmux z)
            bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }

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
            bind "Esc" { SwitchToMode "Normal"; }
            bind "Ctrl c" { SwitchToMode "Normal"; }
            
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
            
            // Enter copy mode
            bind "v" { SwitchToMode "EnterSearch"; }
        }

        // Search mode
        search {
            bind "Esc" { SwitchToMode "Normal"; }
            bind "Ctrl c" { SwitchToMode "Normal"; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Ctrl f" "PageDown" { PageScrollDown; }
            bind "Ctrl b" "PageUp" { PageScrollUp; }
        }

        entersearch {
            bind "Esc" { SwitchToMode "Scroll"; }
            bind "Ctrl c" { SwitchToMode "Normal"; }
            bind "Enter" { SwitchToMode "Search"; }
        }

        // Rename tab mode
        renametab {
            bind "Esc" { UndoRenameTab; SwitchToMode "Normal"; }
            bind "Enter" { SwitchToMode "Normal"; }
        }

        // Session mode
        session {
            bind "Esc" { SwitchToMode "Normal"; }
            bind "d" { Detach; }
        }

        // Shared bindings across modes
        shared_except "locked" {
            bind "Ctrl Space" { SwitchToMode "Tmux"; }
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

