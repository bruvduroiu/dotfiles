# The homelab's private Attic cache (cache.oolongtechnologies.io/homelab),
# as on framework13 (../framework13/attic.nix). The Deck is built from its
# own nixpkgs (nixpkgs-steamdeck), so it only hits paths built at that same
# pin: its own closures, once pushed from a native x86_64 build (homelab
# docs/attic.md, "Framework13 and Steam Deck"). Appended after the caches in
# system/nix/substituters.nix, Jovian's included.
#
# The netrc carries the Deck's own pull-only JWT (sub "steamdeck", 90 days
# from 2026-11-04). Its sops entry: secrets/steamdeck/attic.json, key "netrc".
{ config, inputs, ... }:
{
  imports = [ ../../system/nix/attic-cache.nix ];

  sops.secrets."attic-netrc" = {
    sopsFile = "${inputs.secrets}/secrets/steamdeck/attic.json";
    format = "json";
    key = "netrc";
  };

  oolong.binaryCache = {
    enable = true;
    publicKey = "homelab:i7tWW2dNKrQJ2kk5AsLfPs4Dtu+03GDgu1vWb23xKPM=";
    netrcFile = config.sops.secrets."attic-netrc".path;
  };
}
