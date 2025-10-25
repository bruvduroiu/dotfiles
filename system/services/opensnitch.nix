{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.opensnitch = {
    enable = true;
    
    rules = {
      "block-obsidian" = {
        name = "block-obsidian";
        enabled = true;
        action = "deny";
        duration = "always";
        operator = {
          type = "simple";
          sensitive = false;
          operand = "process.path";
          data = "${lib.getBin pkgs.obsidian}/bin/obsidian";
        };
      };
      
      "allow-systemd-resolved" = {
        name = "allow-systemd-resolved";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          sensitive = false;
          operand = "process.path";
          data = "${pkgs.systemd}/lib/systemd/systemd-resolved";
        };
      };
    };
  };
}
