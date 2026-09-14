{ pkgs, ... }:

let
  # xwayland-satellite 0.8.2 (commit 3273a0f) reports the pointer as leaving
  # Steam's override-redirect menu popups about 35 ms after they map, so every
  # menu-bar and context menu closes the instant it opens, and anything only
  # reachable through those menus (Games → Add a Non-Steam Game) is unreachable.
  # 0.8.1 renders them correctly.
  #   https://github.com/Supreeeme/xwayland-satellite/issues/503
  #   https://github.com/niri-wm/niri/issues/4517
  #   https://github.com/ValveSoftware/steam-for-linux/issues/13566
  # Deck-only: Niri is pointed at this binary through its own config option, so
  # the shared niri.kdl and the other hosts keep whatever nixpkgs ships. Drop
  # this file once a release past 0.8.2 fixes the popup pointer-leave.
  xwaylandSatellite = pkgs.xwayland-satellite.overrideAttrs (old: rec {
    version = "0.8.1";
    src = pkgs.fetchFromGitHub {
      owner = "Supreeeme";
      repo = "xwayland-satellite";
      tag = "v${version}";
      hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
    };
    # buildRustPackage derives cargoDeps from cargoHash at call time, so the
    # vendor derivation has to be replaced, not the hash.
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
    };
  });
in {
  desktop.niri.extraConfig = ''
    // Pinned 0.8.1; see xwayland-satellite-pin.nix.
    xwayland-satellite {
        path "${xwaylandSatellite}/bin/xwayland-satellite"
    }
  '';
}
