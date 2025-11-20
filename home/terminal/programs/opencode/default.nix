{ config
, pkgs
, lib
, ... 
}:

let
  uvxPath = "${pkgs.uv}/bin/uvx";
  opencodeConfigModule = import ./config.nix { inherit lib; };
  opencodeConfig = opencodeConfigModule.config;
in
{
  home.file."${config.xdg.configHome}/opencode/opencode.json".text = builtins.toJSON opencodeConfig;

  home.file."${config.xdg.configHome}/opencode/agent" = {
    source = ./agents;
    recursive = true;
  };

  home.packages = with pkgs; [
    opencode
  ];
}
