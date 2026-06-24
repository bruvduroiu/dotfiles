{
  stylix.targets.firefox.profileNames = [ "default" ];

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox"; # keep legacy path (26.05 default moved to XDG); silences the warning
    profiles.default = {
      path = "4f3s13kd.default";
      isDefault = true;
    };
  };
}
