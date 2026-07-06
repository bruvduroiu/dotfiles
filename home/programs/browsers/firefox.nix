{ pkgs, ... }:

{
  # personal — daily driver. Full arkenfox user.js + OUR maintained overrides
  #            (browsers/arkenfox-overrides.js). RFP stays OFF: you're logged
  #            in, so blending is pointless; the ghost job is Mullvad Browser.
  # work     — sacrificial / walled. Permissive for corp SSO; kept separate so
  #            employer MITM/MDM never touches personal.
  stylix.targets.firefox.profileNames = [ "personal" "work" ];

  programs.firefox =
    let
      # arkenfox user.js — hash-pinned. Applied to `personal`, then overridden
      # by arkenfox-overrides.js (loaded after, so our prefs win).
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

      # daily driver — reuses existing on-disk dir → history + addons + containers intact.
      # arkenfox first (it loses to anything written after it), then OUR overrides win.
      profiles.personal = {
        id = 0;
        isDefault = true;
        path = "4f3s13kd.default";
        extraConfig =
          builtins.readFile arkenfoxUserJs
          + "\n"
          + builtins.readFile ./arkenfox-overrides.js;
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
    };
}
