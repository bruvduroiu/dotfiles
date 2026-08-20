{ pkgs, inputs, ... }:

{
  # Hermes Desktop — client for the Hermes Agent gateway running in the
  # homelab (10.0.20.197:9119). Endpoint config lives in the app's own
  # state (~/.hermes), carried over from previous `nix run` sessions.
  home.packages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
  ];
}
