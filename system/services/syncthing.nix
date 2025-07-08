{ config, ... }:

{
  services.syncthing = {
    enable = true;
    group = "syncthing";
    user = "bogdan";
    dataDir = "/home/bogdan/Documents";
    configDir = "/home/bogdan/Documents/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "Pixel 8a" = { id = "5ZRXJPH-UF6W42O-F6X7T6X-PCUJVTR-ZJGRHYH-ZHKUJLO-WISVGNQ-744CAAX"; };
      };
      folders = {
        "Documents" = {
          path = "/home/bogdan/Documents";
          devices = [ "Pixel 8a" ];
        };
        "Photos" = {
          path = "/home/bogdan/Pictures";
          devices = [ "Pixel 8a" ];
        };
      };
    };
  };
}
