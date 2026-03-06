{ pkgs, ... }:

let
  tbkeys = pkgs.fetchFirefoxAddon {
    name = "tbkeys";
    url = "https://github.com/wshanks/tbkeys/releases/download/v2.4.3/tbkeys.xpi";
    hash = "sha256-2e+T5Nr5kc2s8EykFzWKaJZ2jPUDHh9Cqn4hCuDCLaM=";
  };
in
{
  programs.thunderbird = {
    enable = true;

    profiles.default = {
      isDefault = true;
      extensions = [ tbkeys ];
    };
  };
}
