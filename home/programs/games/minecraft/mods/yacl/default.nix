# Yet Another Config Lib (YACL) - Configuration library
# https://modrinth.com/mod/yacl
# Required by: Controlify
{ pkgs, ... }:

{
  # Mod metadata
  name = "yacl";
  description = "A builder-based configuration library for Minecraft";
  homepage = "https://modrinth.com/mod/yacl";

  # Mod file for Minecraft 1.21.11
  file = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/NWFsMIGn/yet_another_config_lib_v3-3.8.1%2B1.21.11-fabric.jar";
    sha512 = "3a4f015644454dffd423272a8b066e6b94d0f982184ca8c492d996a4f30eb8247b1648fe936413e178d4da3c9266c00e9b864eb9a91f0815348ba5662596986c";
    name = "yacl.jar";
  };

  # No additional config files needed
  configFiles = {};
}
