# Fabric API - Core modding API required by most Fabric mods
# https://modrinth.com/mod/fabric-api
{ pkgs, ... }:

{
  # Mod metadata
  name = "fabric-api";
  description = "Essential hooks for modding with Fabric";
  homepage = "https://modrinth.com/mod/fabric-api";

  # Mod file for Minecraft 1.21.10
  file = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/tV4Gc0Zo/fabric-api-0.138.4%2B1.21.10.jar";
    sha512 = "5e64c53391dfd1c059777d671c52be17a4e27a29d9bd7340ea9e3f55ce7a770b38db0a15e0966e981ee8c1b9372fb89543a278521624689268acebb85bd5c6e9";
    name = "fabric-api.jar";
  };

  # No additional config files needed
  configFiles = {};
}
