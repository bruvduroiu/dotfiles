# Vendored from the homelab flake (bruvduroiu/homelab modules/attic/client.nix),
# so this repo need not import that private flake. Keep in step with it.
# Usage and the token model: homelab docs/attic.md, "Framework13 and Steam Deck".
# Standalone NixOS module, also exported for Framework13 and JovianNixOS.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.oolong.binaryCache;
in
{
  options.oolong.binaryCache = {
    enable = lib.mkEnableOption "the authenticated Oolong binary cache";
    url = lib.mkOption {
      type = lib.types.str;
      default = "https://cache.oolongtechnologies.io/homelab";
    };
    publicKey = lib.mkOption {
      type = lib.types.str;
      description = "Verified Attic cache signing public key (not the JWT key).";
    };
    netrcFile = lib.mkOption {
      type = lib.types.str;
      description = "Absolute runtime path to a root-readable netrc with a pull-only token.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "The Oolong binary cache currently targets x86_64-linux only.";
      }
      {
        assertion = lib.hasPrefix "https://" cfg.url && cfg.publicKey != "";
        message = "Binary cache requires HTTPS and a verified signing public key.";
      }
      {
        assertion = lib.hasPrefix "/" cfg.netrcFile && !(lib.hasPrefix "/nix/store/" cfg.netrcFile);
        message = "Binary cache netrc must be a runtime secret, outside the Nix store.";
      }
    ];
    nix.settings = {
      # Append to the standard cache; never disable signature verification.
      extra-substituters = [ cfg.url ];
      extra-trusted-public-keys = [ cfg.publicKey ];
      netrc-file = cfg.netrcFile;
      builders-use-substitutes = true;
    };
  };
}
