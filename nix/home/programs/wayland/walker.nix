{ inputs, ... }:

{
  imports = [
    inputs.walker.homeManagerModules.default
  ];
  programs.walker = {
    enable = true;
    runAsService = true;
    config = {
      app_launch_prefix = "uwsm app -- ";
    };
  };
}
