{ pkgs, ... }:

{
  # Addons + containers are NOT managed declaratively: omitting `extensions`/
  # `containers` leaves Firefox's own extension DB and containers.json untouched
  # on rebuild. (Avoids NUR as a supply-chain dep; manage addons in-browser.)
  #
  # Three profiles:
  #   personal — daily driver, decently private, KeePassXC autofill, addons kept
  #   work     — permissive, for corp SSO / internal tooling
  #   hardened — "ghost", driven by the arkenfox user.js (hash-pinned below)

  stylix.targets.firefox.profileNames = [ "personal" "work" "hardened" ];

  programs.firefox =
    let
      arkenfoxUserJs =
        let
          version = "144.0";
        in
        pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/arkenfox/user.js/${version}/user.js";
          hash = "sha256-5KszxpFImRdc9wNeDlei1/CKyIfY+VfxGZ5+Sbvn4z4=";
        };

      aiOff = {
        "browser.ai.control.default" = "blocked";
        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
        "browser.ai.control.pdfjsAltText" = "blocked";
        "browser.ai.control.sidebarChatbot" = "blocked";
        "browser.ai.control.smartTabGroups" = "blocked";
        "browser.ai.control.smartWindow" = "blocked";
        "browser.ai.control.translations" = "blocked";
      };

      # shared anti-cruft baseline (no fingerprint/cookie aggression here)
      baseline = aiOff // {
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "extensions.pocket.enabled" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      };
    in
    {
      enable = true;
      configPath = ".mozilla/firefox"; # keep legacy path (26.05 default moved to XDG); silences the warning

      # daily driver — reuses existing on-disk dir → history + addons + containers intact
      profiles.personal = {
        id = 0;
        isDefault = true;
        path = "4f3s13kd.default";
        settings = baseline // {
          "network.trr.mode" = 2; # DoH, fall back to plain on failure
          "network.cookie.cookieBehavior" = 5; # total cookie protection (Firefox ETP-strict default; rarely breaks)
          "signon.rememberSignons" = false; # KeePassXC handles autofill, not Firefox's pw manager
        };
      };

      # permissive profile for corp SSO / internal tooling — starts empty, add addons manually
      profiles.work = {
        id = 1;
        path = "work.work";
        settings = baseline // {
          "network.cookie.cookieBehavior" = 0; # accept all (cross-site SSO redirects)
          "signon.rememberSignons" = true;
        };
      };

      # ghost profile — full arkenfox hardening from the hash-pinned user.js.
      # settings are written before extraConfig, so arkenfox still wins on any
      # overlap; aiOff just guarantees the AI features are off here too.
      #
      # RFP (resistFingerprinting) is OPT-IN in arkenfox 144 — its 4500 section
      # ships every RFP pref commented out (it defers to Tor Browser for real
      # anti-fingerprinting). That left this profile leaking real timezone,
      # screen res, canvas, core count & UA. We re-enable RFP here. Safe because
      # arkenfox never *sets* these prefs, so there's no later overwrite — our
      # earlier `settings` write is the only one in user.js.
      profiles.hardened = {
        id = 2;
        path = "hardened.hardened";
        settings = aiOff // {
          "privacy.resistFingerprinting" = true; # screen->window, UTC clock, 2 cores, canvas randomized, UA frozen
          "privacy.resistFingerprinting.letterboxing" = true; # rounds window to 200x100 steps — kills the 3240x2160 screen leak
          "privacy.spoof_english" = 2; # force en-US UA/locale, drop language entropy
          "webgl.disabled" = true; # remove the (masked-but-present) WebGL fingerprint surface; breaks maps/games
        };
        extraConfig = builtins.readFile arkenfoxUserJs;
      };
    };
}
