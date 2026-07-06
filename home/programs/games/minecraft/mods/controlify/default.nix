# Controlify - Best controller support for Minecraft Java Edition
# https://modrinth.com/mod/controlify
#
# Features:
# - Steam Deck native support (back buttons, gyro, touchpads)
# - Auto-pause when Steam/Quick Access menu opens
# - Vibration/haptics and DualSense HD haptics
# - On-screen keyboard
# - Bedrock-like button guides
# - GUI navigation with controller
# - Gyroscope aiming support
#
# Dependencies: fabric-api, yacl
{ pkgs, lib, ... }:

{
  # Mod metadata
  name = "controlify";
  description = "Adds the best controller support to Minecraft Java Edition";
  homepage = "https://modrinth.com/mod/controlify";

  # Mod file for Minecraft 1.21.11
  file = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/DOUdJVEm/versions/4N7tPBpk/controlify-2.5.0%2B1.21.11-fabric.jar";
    sha512 = "cba7986ff8519a6f99c206f46d7990fccb73d25b3120f99f01f2bdec6b4715826d27aff2f294a2536e01e95fbaf8466b33f107cc7e3e2368fab7ec6d83e7a69e";
    name = "controlify.jar";
  };

  # Default configuration optimized for Steam Deck
  configFiles = {
    "controlify.json" = {
      text = builtins.toJSON {
        # Enable Steam Deck enhanced driver for back buttons, gyro, touchpads
        enhanced_steam_deck_driver = true;
        
        # Auto-calibrate controller deadzones on first use
        auto_calibrate_deadzone = true;
        
        # Show button guides like Bedrock Edition
        show_button_guide = true;
        
        # Enable vibration/haptics
        vibration_enabled = true;
        
        # Enable on-screen keyboard for text input
        virtual_keyboard_enabled = true;
        
        # Use Legacy Console Edition-like controls (optional)
        # Set to true for more console-like feel
        is_lce = false;
      };
      # Don't override if user has customized their settings
      force = false;
    };
  };
}
