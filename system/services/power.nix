{
  services = {
    upower.enable = true;

    logind = {
      settings = {
        Login = {
          HandleLidSwitch = "suspend";
          HandlePowerKey  = "suspend";
        };
      };
    };
  };
}
