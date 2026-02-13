{ ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      cursor-style = "block";
      mouse-hide-while-typing = true;
      background-blur = 10;
      unfocused-split-opacity = 0.9;
      window-padding-x = 0;
      window-padding-y = 0;
      shell-integration = "fish";

      # Splits
      keybind = [
        "ctrl+a>v=new_split:left"
        "ctrl+a>n=new_split:down"
        "ctrl+a>z=toggle_split_zoom"
        "alt+h=goto_split:left"
        "alt+l=goto_split:right"
        "alt+j=goto_split:down"
        "alt+k=goto_split:up"
        "ctrl+a>l=resize_split:right,60"
        "ctrl+a>h=resize_split:left,60"
        "ctrl+a>j=resize_split:down,60"
        "ctrl+a>k=resize_split:up,60"
        # Tabs
        "cmd+t=new_tab"
        "cmd+w=close_tab"
        "ctrl+tab=next_tab"
        "ctrl+shift>tab=previous_tab"
        "ctrl+a>d=close_surface"
        # Terminal
        "global:cmd+grave_accent=toggle_quick_terminal"
      ];
    };
  };
}
