{ ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      cursor-style = "block";
      mouse-hide-while-typing = true;
      background-blur = 10;
      unfocused-split-opacity = 0.7;
      window-padding-x = 0;
      window-padding-y = 0;
      shell-integration = "fish";

      keybind = [
        "clear"

        # clipboard
        "performable:ctrl+shift+c=copy_to_clipboard"
        "performable:ctrl+shift+v=paste_from_clipboard"
        "ctrl+insert=copy_to_clipboard"
        "shift+insert=paste_from_selection"
        "copy=copy_to_clipboard"
        "paste=paste_from_clipboard"

        # selection
        "ctrl+shift+a=select_all"
        "performable:shift+up=adjust_selection:up"
        "performable:shift+down=adjust_selection:down"
        "performable:shift+left=adjust_selection:left"
        "performable:shift+right=adjust_selection:right"

        # scrollback. jump_to_prompt rides the fish shell-integration above.
        "performable:shift+page_up=scroll_page_up"
        "performable:shift+page_down=scroll_page_down"
        "performable:shift+home=scroll_to_top"
        "performable:shift+end=scroll_to_bottom"
        "ctrl+shift+page_up=jump_to_prompt:-1"
        "ctrl+shift+page_down=jump_to_prompt:1"

        # search. `escape` does NOT self-scope to the search overlay; it is
        # bound unconditionally. What keeps it off vim/helix is the
        # `performable:` prefix: end_search reports "not performed" when no
        # search is active, and a performable bind only consumes the key when
        # the action actually ran — so escape falls through to the TTY.
        # Ghostty's own defaults carry this flag (Config.zig, putFlags with
        # .performable = true); `clear` above drops the defaults, so
        # re-declaring these binds means re-declaring the flag too.
        "performable:ctrl+shift+f=start_search"
        "performable:escape=end_search"

        # font size — the one bare-ctrl exception. ctrl+= is the unshifted
        # plus key, so zooming in needs no shift.
        "ctrl+plus=increase_font_size:1"
        "ctrl+equal=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+zero=reset_font_size"

        # ghostty itself
        "ctrl+shift+n=new_window"
        "ctrl+shift+p=toggle_command_palette"
        "ctrl+shift+comma=reload_config"
        "ctrl+shift+i=inspector:toggle"
      ];
    };
  };
}
