{
  stylix.targets.firefox.profileNames = [ "default" ];

  programs.firefox = {
    enable = true;
    profiles.default = {
      path = "4f3s13kd.default";
      isDefault = true;
    };
  };
}
