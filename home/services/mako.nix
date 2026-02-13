{
  services = {
    mako = {
      enable = true;

      settings = {
        sort = "-time";
        border-radius = 2;
        border-size = 3;
        actions = true;
        anchor = "top-right";
        default-timeout = 5000;
        icons = true;
        layer = "overlay";
        padding = "12,20";
        width = 420;
        height = 110;
        margin = 10;
        outer-margin = 20;
        max-icon-size = 32;

        "urgency=critical" = {
          default-timeout = 0;
        };
      };
    };
  };
}
