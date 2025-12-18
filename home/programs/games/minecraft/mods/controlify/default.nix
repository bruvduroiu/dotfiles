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

  # Mod file for Minecraft 1.21.10
  file = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/DOUdJVEm/versions/DsLQgNuV/controlify-2.4.4%2B1.21.10-fabric.jar";
    sha512 = "c616b11d456050ad4c67f5d95225db731b613b91115c294bdf0ef31ef1e7774c6156d7d3a1e2d3bf1f4d5d19180f6dfcb1ac3bc2d4dcece337a22c397520a2e8";
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
