{ config, pkgs, ... }:

{
  programs.k9s = {
    enable = true;
    settings.k9s = {
      liveViewAutoRefresh = false;
      refreshRate = 2;
      maxConnRetry = 5;
      readOnly = false;
      ui = {
        enableMouse = false;
        headless = false;
        logoless = true;
        crumbsless = true;
        noIcons = false;
        # skin = "skin";
      };
    };
  };
}
