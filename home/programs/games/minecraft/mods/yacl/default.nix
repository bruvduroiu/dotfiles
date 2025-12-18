# Yet Another Config Lib (YACL) - Configuration library
# https://modrinth.com/mod/yacl
# Required by: Controlify
{ pkgs, ... }:

{
  # Mod metadata
  name = "yacl";
  description = "A builder-based configuration library for Minecraft";
  homepage = "https://modrinth.com/mod/yacl";

  # Mod file for Minecraft 1.21.10
  file = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/ORi1nScg/yet_another_config_lib_v3-3.8.1%2B1.21.10-fabric.jar";
    sha512 = "3b05fc10d45a631b95aeb974d6a8244cc1fa33449668c72d9988c1e4cb8e63f00e0f2c4a2cb8dab928a449cc261c219cb2ed1dc86c1ba13af710674ffb603def";
    name = "yacl.jar";
  };

  # No additional config files needed
  configFiles = {};
}
