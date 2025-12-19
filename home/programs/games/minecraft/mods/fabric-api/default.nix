# Fabric API - Core modding API required by most Fabric mods
# https://modrinth.com/mod/fabric-api
{ pkgs, ... }:

{
  # Mod metadata
  name = "fabric-api";
  description = "Essential hooks for modding with Fabric";
  homepage = "https://modrinth.com/mod/fabric-api";

  # Mod file for Minecraft 1.21.11
  file = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/5oK85X7C/fabric-api-0.140.0%2B1.21.11.jar";
    sha512 = "f33d3aa6d4da877975eb0f814f9ac8c02f9641e0192402445912ddab43269efcc685ef14d59fd8ee53deb9b6ff4521442e06e1de1fd1284b426711404db5350b";
    name = "fabric-api.jar";
  };

  # No additional config files needed
  configFiles = {};
}
