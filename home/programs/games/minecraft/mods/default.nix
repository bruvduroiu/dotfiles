# Minecraft Mods Aggregator
# This file collects all mod definitions from subdirectories
#
# To add a new mod:
# 1. Create a new folder: mods/<mod-name>/
# 2. Create default.nix with: { pkgs, lib, ... }: { name, description, homepage, file, configFiles }
# 3. The mod will be automatically included
{ pkgs, lib, ... }:

let
  # Import a mod from its directory
  importMod = name: import ./${name} { inherit pkgs lib; };

  # List of enabled mods (directory names)
  # Order matters for dependencies - load dependencies first
  enabledMods = [
    "fabric-api"  # Core API - no dependencies
    "yacl"        # Config library - depends on fabric-api
    "controlify"  # Controller support - depends on fabric-api, yacl
  ];

  # Import all enabled mods
  mods = map importMod enabledMods;

  # Create a lookup table by mod name
  modsByName = lib.listToAttrs (map (mod: { name = mod.name; value = mod; }) mods);

in {
  # List of all mod definitions
  inherit mods;

  # Lookup table for accessing mods by name
  inherit modsByName;

  # List of all mod files (derivations)
  files = map (mod: mod.file) mods;

  # Combined config files from all mods
  # Returns: { "config/modname.json" = { text, force }; ... }
  allConfigFiles = lib.foldl' (acc: mod:
    acc // (lib.mapAttrs' (filename: value: {
      name = "config/${filename}";
      inherit value;
    }) mod.configFiles)
  ) {} mods;

  # Helper to get a specific mod
  getMod = name: modsByName.${name} or (throw "Unknown mod: ${name}");
}
