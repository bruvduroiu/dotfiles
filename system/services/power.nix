{ pkgs, ... }:

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

    udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced"
    '';
  };
}
