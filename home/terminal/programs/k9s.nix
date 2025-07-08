{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ k9s ];
  # https://k9scli.io/topics/skins/
  # https://github.com/derailed/k9s/tree/master/skins
  home.file.".config/k9s/skins/transparent.yaml".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/derailed/k9s/master/skins/transparent.yaml";
    sha256 = "sha256-4+tCRcI5fsSwqqhnNEZiD6LAc6ZW/AaP7KZ0003/XSE=";
  };
  home.file.".config/k9s/config.yaml".text = ''
    k9s:
      liveViewAutoRefresh: false
      refreshRate: 2
      maxConnRetry: 5
      readOnly: false
      ui:
        enableMouse: false
        headless: false
        logoless: true
        crumbsless: true
        noIcons: false
        # Uses skin located in your $XDG_CONFIG_HOME/skins/
        skin: transparent
  '';
}
