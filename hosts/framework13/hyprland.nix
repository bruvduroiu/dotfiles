{
  programs.hyprland = let
    # TODO
    accelpoints = "0.000 0.391 1.375 3.422 7.000 12.578 20.625 31.609 46.000 64.266 86.875 114.297 146.000 185.453 230.125 281.484 340.000 406.141 480.375 563.172";
  in {
    # --- hyprlang fallback (still generated; .lua shadows it at startup) ------
    settings = {
      misc = {
        vrr = 1;
      };

      monitor = [
        "DP-4, 3840x2160@60.00, 0x0, 1, vrr, 1"
        "eDP-1, preferred, 3840x0, 1, vrr, 1"
      ];

      # Deep work on the external 4K, comms/overflow on the laptop panel.
      # Hyprland reassigns automatically when DP-4 is unplugged.
      workspace = [
        "1, monitor:DP-4, default:true"
        "2, monitor:DP-4"
        "3, monitor:DP-4"
        "4, monitor:eDP-1, default:true"
        "5, monitor:eDP-1"
      ];

      "device[pixa3854:00-093a:0274-touchpad]" = {
        accel_profile = "custom ${accelpoints}";
        scroll_points = accelpoints;
        natural_scroll = true;
      };
    };

    # --- Lua host prelude (injected into hyprland.lua by lua.nix) -------------
    # Mirrors the settings above. See docs/hyprland-lua-migration.md.
    luaPrelude = ''
      -- VRR on for both outputs
      hl.config({ misc = { vrr = 1 } })

      -- Deep work on the external 4K, comms/overflow on the laptop panel.
      hl.monitor({ output = "DP-4",  mode = "3840x2160@60.00", position = "0x0",    scale = 1,      vrr = 1 })
      hl.monitor({ output = "eDP-1", mode = "preferred",       position = "3840x0", scale = 1.3333, vrr = 1 })

      -- Pin workspaces to monitors (Hyprland reassigns when DP-4 is unplugged).
      hl.workspace_rule({ workspace = "1", monitor = "DP-4",  default = true })
      hl.workspace_rule({ workspace = "2", monitor = "DP-4" })
      hl.workspace_rule({ workspace = "3", monitor = "DP-4" })
      hl.workspace_rule({ workspace = "4", monitor = "eDP-1", default = true })
      hl.workspace_rule({ workspace = "5", monitor = "eDP-1" })

      -- Custom touchpad acceleration + scroll curve.
      hl.device({
        name = "pixa3854:00-093a:0274-touchpad",
        accel_profile = "custom ${accelpoints}",
        scroll_points = "${accelpoints}",
        natural_scroll = true,
      })
    '';
  };
}
