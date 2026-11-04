# The homelab's private Attic cache (cache.oolongtechnologies.io/homelab):
# what its CI builds (kratos, comply, oolong-site) downloads here instead of
# compiling, when built at the same nixpkgs pin. Appended after the caches in
# system/nix/substituters.nix; cache.nixos.org stays first.
#
# The netrc carries this laptop's own pull-only JWT (sub "framework13",
# 90 days from 2026-11-04), separate from the servers' token so either can
# be revoked alone. Its sops entry lives in the secrets flake as
# secrets/framework13/attic.json, key "netrc", one line:
#   machine cache.oolongtechnologies.io login attic password <JWT>
{ config, inputs, ... }:
{
  imports = [ ../../system/nix/attic-cache.nix ];

  sops.secrets."attic-netrc" = {
    sopsFile = "${inputs.secrets}/secrets/framework13/attic.json";
    format = "json";
    key = "netrc";
  };

  oolong.binaryCache = {
    enable = true;
    publicKey = "homelab:i7tWW2dNKrQJ2kk5AsLfPs4Dtu+03GDgu1vWb23xKPM=";
    netrcFile = config.sops.secrets."attic-netrc".path;
  };
}
