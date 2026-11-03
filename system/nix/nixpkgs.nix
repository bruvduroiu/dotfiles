{ self, inputs, ... }:

{
  nixpkgs = {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "electron-25.9.0"
    ];

    overlays = [
      inputs.nur.overlays.default
      inputs.mcp-servers-nix.overlays.default
      (final: prev: {
        lib = prev.lib // {
          colors = import "${self}/lib/colors" prev.lib;
        };
        claude-code = prev.callPackage "${self}/pkgs/claude.nix" {
          version = "2.1.303";
          hashes = {
            "x86_64-linux" = "sha256-N1mI9Fd1ZSQjRpXPLY9krOmcX2hoLkfqJIYqhDwZFFA=";
            "aarch64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
        };
        # 26.05 pins codex 0.133; the config.toml schema this repo writes
        # (permission profiles, `web_search` modes, `tui.notification_method`)
        # only exists from ~0.140 onwards. Same treatment as opencode below.
        codex = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.codex;
        terraform-mcp-server =
          inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.terraform-mcp-server;
        keymapp =
          (import inputs.nixpkgs-unstable.outPath {
            system = prev.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          }).keymapp;
        gh-actions-language-server = prev.callPackage "${self}/pkgs/gh-actions-language-server.nix" { };
        tailsnitch = prev.callPackage "${self}/pkgs/tailsnitch.nix" { };
        tabiew = prev.callPackage "${self}/pkgs/tabiew.nix" { };
        lazy-zellij = prev.callPackage "${self}/pkgs/lazy-zellij.nix" { };
        skepsis = prev.callPackage "${self}/pkgs/skepsis.nix" { };
        uber-receipts = prev.callPackage "${self}/pkgs/uber-receipts" { };
        portfolio-tracker = prev.callPackage "${self}/pkgs/portfolio-tracker" { };
        hister = prev.callPackage "${self}/pkgs/hister.nix" { };
        md2pdf = prev.callPackage "${self}/pkgs/md2pdf" { };
        mullvad-jump = prev.callPackage "${self}/pkgs/mullvad-jump.nix" { };
        phantom-unlock = prev.callPackage "${self}/pkgs/phantom-unlock.nix" { };
        invoice = prev.callPackage "${self}/pkgs/invoice.nix" {
          srcHash = "sha256-Qa7lTpRBB3m3GiK5mBkDMyg0InUqziUANf5Ds5XDnGg=";
          vendorHash = "sha256-mLn9hN7hd3MPYx0STiwCL8pTTYtDlycVkSLUEq8NZOE=";
        };
        podman = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.podman;
        podman-compose =
          inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.podman-compose;
        librepods = prev.callPackage "${self}/pkgs/librepods.nix" { };
        obsidian =
          (import inputs.nixpkgs-unstable.outPath {
            system = prev.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          }).obsidian;
        # Floor, not a pin (same scheme as the homelab opencode guest): when
        # upstream outruns the lock, rebuild unstable's recipe at a newer tag.
        # Bump version + both hashes (lib.fakeHash, copy "got:"; node_modules
        # is a FOD over `bun install`). Once the lock reaches the floor the
        # cached nixpkgs build wins and this can go.
        opencode =
          let
            pinned = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.opencode;
            floor = {
              version = "2.2.5";
              srcHash = "sha256-/a1czcXi12KWPXcESqplNdOZcjEs8gWCMO7w4nQYLkw=";
              nodeModulesHash = "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc=";
            };
          in
          if prev.lib.versionOlder pinned.version floor.version then
            pinned.overrideAttrs (
              finalAttrs: old: {
                inherit (floor) version;
                src = old.src.override {
                  tag = "v${finalAttrs.version}";
                  hash = floor.srcHash;
                };
                # node_modules already follows finalAttrs.src; only its
                # fixed-output hash is baked into the recipe.
                node_modules = old.node_modules.overrideAttrs {
                  outputHash = floor.nodeModulesHash;
                };
              }
            )
          else
            pinned;
        # Inherits version/src/node_modules from `opencode`, so it follows the
        # floor above and stays in lockstep with the CLI.
        opencode-desktop =
          let
            unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
            pinned = unstable.opencode-desktop;
            # The launcher wraps unstable's electron; package against the same one.
            inherit (unstable) electron_44;
            desktop = pinned.override { inherit (final) opencode; };
          in
          if pinned.version == final.opencode.version then
            desktop
          else
            # ≥2.2 renamed scripts/ → script/ and bundles the CLI from
            # packages/cli/dist (no OPENCODE_CLI_DIST); `bun run build` now
            # copies the channel's icons itself. Drop with the floor.
            desktop.overrideAttrs {
              buildPhase = ''
                runHook preBuild

                cd packages/desktop

                cli_package=$(bun -e 'import { getCurrentCli } from "./script/utils.ts"; console.log(getCurrentCli().package.replace("@opencode/", ""))')
                mkdir -p "../cli/dist/$cli_package/bin"
                cp ${prev.lib.getExe final.opencode} "../cli/dist/$cli_package/bin/opencode"
                echo '{"version":"${final.opencode.version}"}' > "../cli/dist/$cli_package/package.json"

                bun run build

                cp -r "${electron_44.dist}" $HOME/.electron-dist
                chmod -R u+w $HOME/.electron-dist

                npx electron-builder --dir \
                  --config=electron-builder.config.ts \
                  --config.electronDist="$HOME/.electron-dist" \
                  --config.electronVersion=${electron_44.version}

                cd ../..

                runHook postBuild
              '';
            };
        # Unstable's v18 unvendors ffmpeg/curl-impersonate/libsodium/sqlite and
        # drops FUTO.Updater.Client.
        grayjay =
          (import inputs.nixpkgs-unstable.outPath {
            system = prev.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          }).grayjay;
        sheets = prev.callPackage "${self}/pkgs/sheets.nix" { };
        hey-cli = prev.callPackage "${self}/pkgs/hey-cli.nix" { };
        sqlit-tui = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.sqlit-tui;
        google-cloud-sdk = prev.google-cloud-sdk.overrideAttrs (oldAttrs: rec {
          version = "563.0.0";
          src = prev.fetchurl {
            url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${version}-linux-x86_64.tar.gz";
            hash = "sha256-LN5Bn5H6P2LtvRiEHsrawHB3LFLsHrqsmZh0Er1mzQE=";
          };
          installCheckPhase = ''
            export HOME=$(mktemp -d)
            $out/bin/gcloud version --format json | jq '."Google Cloud SDK"' | grep "${version}"
          '';
        });
        zulip-term = prev.zulip-term.overrideAttrs (oldAttrs: {
          src = prev.fetchFromGitHub {
            owner = "zulip";
            repo = "zulip-terminal";
            rev = "6a799870eccc00d612e25ff881d18f4ff66d92fa";
            hash = "sha256-saimbccJ5iJITs/Bw97bOkGrVcko1kAl61nlxNwBrms=";
          };
        });
      })
    ];
  };
}
