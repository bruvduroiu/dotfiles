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
        claude-code = prev.callPackage "${self}/pkgs/claude.nix" {};
        terraform-mcp-server = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.terraform-mcp-server;
        keymapp = (import inputs.nixpkgs-unstable.outPath {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        }).keymapp;
        gh-actions-language-server = prev.callPackage "${self}/pkgs/gh-actions-language-server.nix" {};
        tailsnitch = prev.callPackage "${self}/pkgs/tailsnitch.nix" {};
        tabiew = prev.callPackage "${self}/pkgs/tabiew.nix" {};
        uber-receipts = prev.callPackage "${self}/pkgs/uber-receipts" {};
        hister = prev.callPackage "${self}/pkgs/hister.nix" {};
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
        sheets = prev.callPackage "${self}/pkgs/sheets.nix" {
          srcHash = "sha256-sRJ1rqtxc4axAkVavxSR2afdvxCAjJdK2mBWnt+nzW0=";
          vendorHash = "sha256-WWtAt0+W/ewLNuNgrqrgho5emntw3rZL9JTTbNo4GsI=";
        };
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
