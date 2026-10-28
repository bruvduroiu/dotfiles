# NixOS module. The host owns secrets: it points environmentFile at a sops-nix
# secret (config.sops.secrets.<name>.path). This module never imports sops.
{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.myapp;
in
{
  options.services.myapp = {
    enable = lib.mkEnableOption "myapp";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "myapp.packages.\${system}.default";
    };

    # str, not path: a Nix path literal here would copy the secret into the
    # world-readable store. Only runtime paths like /run/secrets/… type-check.
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = lib.literalExpression "config.sops.secrets.myapp-env.path";
      description = "dotenv file with secrets, read by systemd at service start.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Non-secret environment variables.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.myapp = {
      description = "myapp";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      inherit (cfg) environment;

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        Restart = "on-failure";

        DynamicUser = true;
        StateDirectory = "myapp";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        SystemCallFilter = [ "@system-service" ];
      };
    };
  };
}
