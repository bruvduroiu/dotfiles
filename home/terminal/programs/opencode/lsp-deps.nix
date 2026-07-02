# node_modules for editor LSP on tools/*.ts, assembled from npm tarballs so
# no package.json/npm install is needed in the repo. Only type-level deps of
# @opencode-ai/plugin are included (runtime deps like effect/cross-spawn and
# the @opentui/* TUI types are skipped — tsconfig has skipLibCheck).
#
# On opencode bumps: update `version` to match `pkgs.opencode.version` and
# refresh hashes with `nix store prefetch-file <url>`.
{ pkgs }:

let
  version = "1.17.7"; # keep in lockstep with pkgs.opencode.version

  plugin = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opencode-ai/plugin/-/plugin-${version}.tgz";
    hash = "sha256-mp2F6+tKssF8ddp0MfglXAalCoNJ/sJkuYa/r3OZ26M=";
  };
  sdk = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opencode-ai/sdk/-/sdk-${version}.tgz";
    hash = "sha256-O3LqoqmxUJk28BiQm6wyF7d0YEgApsBKO4qSxT9fK9Q=";
  };
  zod = pkgs.fetchurl {
    url = "https://registry.npmjs.org/zod/-/zod-4.1.8.tgz";
    hash = "sha256-GT46M9xm1nnVIsQOalE4eIZG08alA50MXCs77eg7ZjU=";
  };
  typesNode = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@types/node/-/node-26.1.0.tgz";
    hash = "sha256-uZ7FfP3SglaiK5MIQlcJ6clPv9s96h/WqxkwEK2wGDI=";
  };
in
pkgs.runCommand "opencode-lsp-node-modules" { } ''
  unpack() {
    mkdir -p "$2"
    tar -xzf "$1" -C "$2" --strip-components=1
  }
  unpack ${plugin} $out/@opencode-ai/plugin
  unpack ${sdk} $out/@opencode-ai/sdk
  unpack ${zod} $out/zod
  unpack ${typesNode} $out/@types/node
''
