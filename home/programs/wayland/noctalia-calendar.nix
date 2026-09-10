{ config, lib, ... }:
let
  cfg = config.programs.noctalia;
in
{
  options.programs.noctalia.privateCalendarFile = lib.mkOption {
    type = lib.types.nullOr (lib.types.strMatching "/.*");
    default = null;
    description = "Runtime path to a private TOML file containing calendar accounts.";
  };

  config = lib.mkIf (cfg.privateCalendarFile != null) {
    programs.noctalia.settings.calendar = {
      enabled = true;
      refresh_minutes = 15;
    };

    xdg.configFile."noctalia/calendar-private.toml".source =
      config.lib.file.mkOutOfStoreSymlink cfg.privateCalendarFile;

    # Order after decryption, but keep the desktop usable if SOPS fails.
    systemd.user.services.noctalia.Unit = {
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
  };
}
