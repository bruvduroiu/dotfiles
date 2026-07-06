{ pkgs, ... }:

{
  services.trayscale = {
    enable = true;
  };

  systemd.user.services.trayscale = {
    Unit.Requires = [ "graphical-session.target" ];
    Service = {
      ExecStart = "${pkgs.trayscale}/bin/trayscale --hide-window";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 5;
    };
  };
}
