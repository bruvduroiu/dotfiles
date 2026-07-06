# Declarative Minecraft Game Options
# Generates options.txt from Nix configuration
{ lib, ... }:

let
  # Game options - modify these as needed
  # Reference: https://minecraft.wiki/w/Options.txt
  options = {
    # Version (don't change unless you know what you're doing)
    version = 3700;

    # Video Settings
    renderDistance = 12;          # Chunks (2-32)
    simulationDistance = 12;      # Chunks
    maxFps = 120;                 # FPS limit (10-260, or 260 for unlimited)
    graphicsMode = 1;             # 0=Fast, 1=Fancy, 2=Fabulous
    ao = true;                    # Smooth lighting
    enableVsync = false;          # VSync
    guiScale = 0;                 # 0=Auto, 1-4=Fixed
    fullscreen = false;
    entityDistanceScaling = 1.0;  # Entity render distance (0.5-5.0)
    mipmapLevels = 4;             # Mipmap (0-4)
    biomeBlendRadius = 2;         # Biome blend (0-7)
    renderClouds = "true";        # Clouds: "true", "false", "fast"
    particles = 0;                # 0=All, 1=Decreased, 2=Minimal
    entityShadows = true;

    # Camera/Controls
    fov = 0.0;                    # FOV: -1.0 (30) to 1.0 (110), 0.0 = 70 (normal)
    mouseSensitivity = 0.5;       # 0.0-1.0
    invertYMouse = false;
    rawMouseInput = true;
    autoJump = false;             # Auto-jump (annoying, disable)
    toggleCrouch = false;
    toggleSprint = false;
    bobView = true;               # View bobbing
    
    # Accessibility
    gamma = 0.5;                  # Brightness: 0.0 (Moody) to 1.0 (Bright)
    showSubtitles = false;
    narrator = 0;                 # 0=Off, 1=All, 2=Chat, 3=System
    darkMojangStudiosBackground = true;  # Easier on eyes
    
    # Chat/UI
    chatVisibility = 0;           # 0=Shown, 1=Commands only, 2=Hidden
    chatOpacity = 1.0;
    chatScale = 1.0;
    chatWidth = 1.0;
    chatHeightFocused = 1.0;
    chatHeightUnfocused = 0.4375;
    
    # Misc
    pauseOnLostFocus = true;      # Pause when window loses focus
    advancedItemTooltips = false; # F3+H tooltips
    realmsNotifications = false;  # Disable Realms ads
    tutorialStep = "none";        # Skip tutorial
    skipMultiplayerWarning = true;
    skipRealms32bitWarning = true;

    # Language
    lang = "en_us";

    # Resource packs
    resourcePacks = [ "vanilla" "Fabric Mods" ];
    incompatibleResourcePacks = [];

    # Main hand
    mainHand = "right";           # "left" or "right"
  };

  # Convert Nix values to options.txt format
  formatValue = v:
    if builtins.isList v then 
      "[${lib.concatMapStringsSep "," (x: "\"${toString x}\"") v}]"
    else if builtins.isBool v then 
      (if v then "true" else "false")
    else if builtins.isString v then
      v
    else 
      toString v;

  # Generate options.txt content
  optionsText = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "${k}:${formatValue v}") options
  );

in {
  inherit options optionsText;
  
  # For use in xdg.configFile
  configFile = {
    text = optionsText;
    # Don't force - let user customize in-game, only set defaults
    force = false;
  };
}
