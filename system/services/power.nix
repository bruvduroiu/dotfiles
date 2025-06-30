{
  services = {
    upower.enable = true;

    logind = {
      powerKey = "suspend";
      lidSwitch = "suspend";
    };
  };
}
