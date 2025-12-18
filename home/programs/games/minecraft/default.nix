# Declarative Minecraft Configuration for Steam Deck
# 
# This module provides:
# - Prism Launcher with multiple Java versions
# - Declarative mod management (mods defined in mods/<name>/default.nix)
# - Declarative server list (servers.nix)
# - Declarative game options (options.nix)
# - Automatic setup on home-manager switch
# - Steam integration helpers
#
# Directory Structure:
# minecraft/
# ├── default.nix          # This file - main configuration
# ├── servers.nix          # Server list configuration
# ├── options.nix          # Game options (FOV, render distance, etc.)
# └── mods/
#     ├── default.nix      # Mod aggregator
#     ├── fabric-api/      # Fabric API mod
#     │   └── default.nix
#     ├── yacl/            # Yet Another Config Lib
#     │   └── default.nix
#     └── controlify/      # Controller support
#         └── default.nix
#
{ config, pkgs, lib, ... }:

let
  # Minecraft version configuration
  mcVersion = "1.21.10";
  fabricLoaderVersion = "0.18.3";
  instanceName = "${mcVersion}";

  # Import configurations
  modsConfig = import ./mods { inherit pkgs lib; };
  serversConfig = import ./servers.nix { inherit pkgs lib; };
  optionsConfig = import ./options.nix { inherit lib; };

  # Create a directory containing all mod files
  modsDir = pkgs.linkFarmFromDrvs "minecraft-mods-${mcVersion}" modsConfig.files;

  # Prism Launcher with multiple Java versions
  prismlauncher = pkgs.prismlauncher.override {
    jdks = [
      pkgs.jdk21  # For 1.21.x
      pkgs.jdk17  # For 1.18-1.20.x
      pkgs.jdk8   # For older versions
    ];
    gamemodeSupport = true;
  };

  # Instance configuration file content
  instanceCfg = ''
    [General]
    AutoCloseConsole=false
    AutomaticJava=true
    CloseAfterLaunch=false
    ConfigVersion=1.2
    IgnoreJavaCompatibility=false
    InstanceType=OneSix
    LogPrePostOutput=true
    ManagedPack=false
    MaxMemAlloc=4096
    MinMemAlloc=512
    OverrideJavaLocation=false
    OverrideMemory=false
    iconKey=default
    name=${instanceName}
    notes=Declaratively managed by Nix
  '';

  # mmc-pack.json for Fabric loader configuration
  mmcPackJson = builtins.toJSON {
    formatVersion = 1;
    components = [
      {
        cachedName = "LWJGL 3";
        cachedVersion = "3.3.3";
        cachedVolatile = true;
        dependencyOnly = true;
        uid = "org.lwjgl3";
        version = "3.3.3";
      }
      {
        cachedName = "Minecraft";
        cachedRequires = [
          { suggests = "3.3.3"; uid = "org.lwjgl3"; }
        ];
        cachedVersion = mcVersion;
        important = true;
        uid = "net.minecraft";
        version = mcVersion;
      }
      {
        cachedName = "Intermediary Mappings";
        cachedRequires = [
          { equals = mcVersion; uid = "net.minecraft"; }
        ];
        cachedVersion = mcVersion;
        cachedVolatile = true;
        dependencyOnly = true;
        uid = "net.fabricmc.intermediary";
        version = mcVersion;
      }
      {
        cachedName = "Fabric Loader";
        cachedRequires = [
          { uid = "net.fabricmc.intermediary"; }
        ];
        cachedVersion = fabricLoaderVersion;
        uid = "net.fabricmc.fabric-loader";
        version = fabricLoaderVersion;
      }
    ];
  };

  # Create a directory with all config files for the setup script
  configFilesDir = pkgs.runCommand "minecraft-configs-${mcVersion}" {} ''
    mkdir -p $out
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (path: value: ''
      mkdir -p $out/$(dirname "${path}")
      cat > $out/${path} << 'CONFIGEOF'
${value.text}
CONFIGEOF
    '') allConfigFiles)}
  '';

  # Setup script for mod installation
  setupMinecraftScript = pkgs.writeShellScriptBin "minecraft-setup" ''
    set -euo pipefail

    PRISM_DATA="$HOME/.local/share/PrismLauncher"
    INSTANCE_NAME="${instanceName}"
    INSTANCE_DIR="$PRISM_DATA/instances/$INSTANCE_NAME"
    MODS_SRC="${modsDir}"
    CONFIGS_SRC="${configFilesDir}"

    echo "============================================"
    echo "  Minecraft Declarative Setup"
    echo "============================================"
    echo ""
    echo "Instance: $INSTANCE_NAME"
    echo "Minecraft: ${mcVersion}"
    echo "Mod Loader: Fabric ${fabricLoaderVersion}"
    echo ""

    # Create instance directory structure
    mkdir -p "$INSTANCE_DIR/.minecraft/mods"
    mkdir -p "$INSTANCE_DIR/.minecraft/config"

    # === INSTANCE METADATA ===
    # Create instance.cfg if it doesn't exist
    if [ ! -f "$INSTANCE_DIR/instance.cfg" ]; then
      echo "Creating instance metadata..."
      cat > "$INSTANCE_DIR/instance.cfg" << 'INSTANCECFG'
    ${instanceCfg}
    INSTANCECFG
    fi

    # Create mmc-pack.json if it doesn't exist
    if [ ! -f "$INSTANCE_DIR/mmc-pack.json" ]; then
      echo "Creating mod loader configuration..."
      cat > "$INSTANCE_DIR/mmc-pack.json" << 'MMCPACK'
    ${mmcPackJson}
    MMCPACK
    fi

    # === MODS ===
    echo "Syncing declarative mods..."
    
    MANAGED_MODS="$INSTANCE_DIR/.minecraft/mods/.nix-managed"
    
    # Remove previously managed mods
    if [ -f "$MANAGED_MODS" ]; then
      while IFS= read -r mod; do
        if [ -f "$INSTANCE_DIR/.minecraft/mods/$mod" ]; then
          echo "  - Removing old: $mod"
          rm -f "$INSTANCE_DIR/.minecraft/mods/$mod"
        fi
      done < "$MANAGED_MODS"
    fi

    > "$MANAGED_MODS"

    # Install mods
    echo ""
    echo "Installing mods:"
    for mod in "$MODS_SRC"/*; do
      mod_name=$(basename "$mod")
      echo "  + $mod_name"
      cp -f "$mod" "$INSTANCE_DIR/.minecraft/mods/$mod_name"
      echo "$mod_name" >> "$MANAGED_MODS"
    done

    # === CONFIG FILES ===
    # Install config files only if they don't exist (preserves user customizations)
    echo ""
    echo "Checking config files:"
    configs_created=0
    find "$CONFIGS_SRC" -type f | while read -r config_src; do
      config_rel="''${config_src#$CONFIGS_SRC/}"
      config_dest="$INSTANCE_DIR/.minecraft/$config_rel"
      
      if [ ! -f "$config_dest" ]; then
        mkdir -p "$(dirname "$config_dest")"
        cp "$config_src" "$config_dest"
        echo "  + Created: $config_rel"
        configs_created=$((configs_created + 1))
      else
        echo "  ~ Exists: $config_rel (preserving user settings)"
      fi
    done

    # === SERVERS ===
    echo ""
    ${serversConfig.setupScript}

    echo ""
    echo "============================================"
    echo "  Setup Complete!"
    echo "============================================"
    echo ""
    echo "Mods installed: $(wc -l < "$MANAGED_MODS")"
    echo "Servers configured: ${toString (builtins.length serversConfig.servers)}"
    echo ""
    echo "Instance '$INSTANCE_NAME' is ready in Prism Launcher!"
    echo ""
    echo "To add to Steam Gaming Mode, run: minecraft-add-to-steam"
  '';

  # Steam integration helper
  addToSteamScript = pkgs.writeShellScriptBin "minecraft-add-to-steam" ''
    echo "============================================"
    echo "  Add Minecraft to Steam Gaming Mode"
    echo "============================================"
    echo ""
    echo "To add Prism Launcher to Steam:"
    echo ""
    echo "1. Switch to Desktop Mode"
    echo "2. Open Steam"
    echo "3. Games → Add a Non-Steam Game"
    echo "4. Browse to: ${prismlauncher}/bin/prismlauncher"
    echo "5. Click 'Add Selected Programs'"
    echo ""
    echo "Or select 'Minecraft (Controller)' from the list."
    echo ""
    echo "The game will appear in Gaming Mode!"
  '';

  # Combine all config files
  allConfigFiles = modsConfig.allConfigFiles // {
    # Add options.txt
    "options.txt" = optionsConfig.configFile;
  };

in {
  home.packages = [
    prismlauncher
    setupMinecraftScript
    addToSteamScript
    pkgs.ferium  # CLI mod manager for manual updates
  ];

  # Run setup on home-manager switch
  home.activation.setupMinecraftMods = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${setupMinecraftScript}/bin/minecraft-setup
  '';

  # Desktop entry for Steam discovery
  xdg.desktopEntries.minecraft-controller = {
    name = "Minecraft (Controller)";
    genericName = "Minecraft";
    comment = "Minecraft Java Edition with controller support";
    exec = "${prismlauncher}/bin/prismlauncher";
    icon = "prismlauncher";
    categories = [ "Game" ];
    terminal = false;
    settings = {
      StartupWMClass = "PrismLauncher";
      Keywords = "minecraft;game;gaming;";
    };
  };

  # Config files are now installed by the setup script (copy if not exists)
  # This preserves user customizations made in-game
}
