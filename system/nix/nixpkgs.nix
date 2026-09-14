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
        lib = 
          prev.lib
          // {
            colors = import "${self}/lib/colors" prev.lib;
          };
        claude-code = prev.callPackage "${self}/pkgs/claude.nix" {
          version = "2.1.257";
          hashes = {
            "x86_64-linux" = "sha256-mmS9qdhyKh+gW++aWWHQfgMxuZWX7ani9qcy86D/fwU=";
            "aarch64-linux" = "sha256-IvfUjxcZOVLDwtC4vy8x2yzQj9X7CaN0+jIUlrcR0Bc=";
          };
        };
        # 26.05 pins codex 0.133; the config.toml schema this repo writes
        # (permission profiles, `web_search` modes, `tui.notification_method`)
        # only exists from ~0.140 onwards. Same treatment as opencode below.
        codex = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.codex;
        terraform-mcp-server = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.terraform-mcp-server;
        keymapp = (import inputs.nixpkgs-unstable.outPath {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        }).keymapp;
        gh-actions-language-server = prev.callPackage "${self}/pkgs/gh-actions-language-server.nix" {};
        tailsnitch = prev.callPackage "${self}/pkgs/tailsnitch.nix" {};
        tabiew = prev.callPackage "${self}/pkgs/tabiew.nix" {};
        uber-receipts = prev.callPackage "${self}/pkgs/uber-receipts" {};
        portfolio-tracker = prev.callPackage "${self}/pkgs/portfolio-tracker" {};
        hister = prev.callPackage "${self}/pkgs/hister.nix" {};
        md2pdf = prev.callPackage "${self}/pkgs/md2pdf" {};
        mullvad-jump = prev.callPackage "${self}/pkgs/mullvad-jump.nix" {};
        phantom-unlock = prev.callPackage "${self}/pkgs/phantom-unlock.nix" {};
        invoice = prev.callPackage "${self}/pkgs/invoice.nix" {
          srcHash = "sha256-Qa7lTpRBB3m3GiK5mBkDMyg0InUqziUANf5Ds5XDnGg=";
          vendorHash = "sha256-mLn9hN7hd3MPYx0STiwCL8pTTYtDlycVkSLUEq8NZOE=";
        };
        podman = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.podman;
        podman-compose = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.podman-compose;
        librepods = prev.callPackage "${self}/pkgs/librepods.nix" {};
        obsidian = (import inputs.nixpkgs-unstable.outPath {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        }).obsidian;
        opencode = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.opencode;
        sheets = prev.callPackage "${self}/pkgs/sheets.nix" {
          srcHash = "sha256-xDu+jbWH7ubXC6ImvkRVgPI0OHAaUQ60sELDJN8hY1M=";
          vendorHash = "sha256-X7bfALH9mM15HP6SM60CFIG1rm4Ma6LEh2p7z5LNW64=";
        };
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
