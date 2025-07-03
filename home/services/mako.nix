{
  services = {
    mako = {
      enable = true;

      settings = {
        sort = "-time";
        text-color = "#a9b1d6";
        border-color = "#3f3f3f";
        border-radius = 2;
        border-size = 3;
        background-color = "#1a1b26";
        actions = true;
        anchor = "top-right";
        default-timeout = 5000;
        icons = true;
        layer = "overlay";
        padding = "12,20";
        width = 420;
        height = 120;
        margin = 12;

        "urgency=low" = {
          border-color = "#cccccc";
        };

        "urgency=normal" = {
          border-color = "#99c0d0";
        };

        "urgency=critical" = {
          border-color = "#bf616a";
          default-timeout = 0;
        };
      };
    };
  };
}
