/*** arkenfox user-overrides.js — `personal` profile (identified daily driver)
 *
 * Loaded AFTER arkenfox's user.js, so every pref here WINS over arkenfox.
 * This file is OURS to own — arkenfox itself says you MUST maintain overrides
 * and read the wiki; treat it as the single place we relax/tighten arkenfox.
 *
 * Deliberately NO resistFingerprinting here: `personal` is logged-in, so
 * blending into a crowd is pointless and just breaks sites. The ghost/anonymity
 * job lives in Mullvad Browser (browsers/mullvad.nix), not this profile.
 ***/

/* --- light anti-fingerprinting: FPP, NOT RFP ---------------------------
 * FPP randomizes canvas + audio (and curbs some enumeration) per-site,
 * per-session, WITHOUT RFP's usability tax (no UTC clock, no letterbox, no
 * forced theme). The right tier for a logged-in driver: it neutralizes the
 * STABLE cross-site IDs (canvas/audio) that survive cookie partitioning —
 * exactly personal's anti-correlation goal. arkenfox leaves these at default
 * (off in normal windows on non-strict ETP), so set them explicitly. */
user_pref("privacy.fingerprintingProtection", true);        // [arkenfox: default/off in normal windows]
user_pref("privacy.fingerprintingProtection.pbmode", true); // also in private windows
/* FPP=true only ARMS the engine; which targets fire comes from remote-settings
 * and did NOT include canvas (verified: toDataURL stayed at the unprotected
 * hash). Force the canvas target locally so readback is noised per-session.
 * `+Target` augments the remote set; CanvasRandomization is the silent one
 * (CanvasImageExtractionPrompt would nag on every extraction — omitted). */
user_pref("privacy.fingerprintingProtection.overrides", "+CanvasRandomization");

/* --- stay logged in across restarts ------------------------------------
 * arkenfox 2811 wipes cookies + storage on shutdown -> logged out every
 * restart. Keep the rest of the shutdown wipe (cache, formdata) but persist
 * logins. This is the single change that makes arkenfox livable as a daily. */
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false); // [arkenfox: true]

/* --- daily-driver quality of life --------------------------------------- */
user_pref("browser.cache.disk.enable", true);       // [arkenfox: false] still wiped on shutdown via clearOnShutdown_v2.cache
user_pref("browser.startup.page", 3);               // [arkenfox: 0] restore previous session (cookies now persist)
user_pref("browser.sessionstore.privacy_level", 0); // [arkenfox: 2] let session restore actually work

/* --- our standing prefs (arkenfox leaves these at default/unset) -------- */
user_pref("network.trr.mode", 2);                   // DoH, fall back to plain DNS on failure
user_pref("signon.rememberSignons", false);         // KeePassXC handles autofill, not Firefox's pw manager

/* --- AI off (arkenfox doesn't touch browser.ai.control) ----------------- */
user_pref("browser.ai.control.default", "blocked");
user_pref("browser.ai.control.linkPreviewKeyPoints", "blocked");
user_pref("browser.ai.control.pdfjsAltText", "blocked");
user_pref("browser.ai.control.sidebarChatbot", "blocked");
user_pref("browser.ai.control.smartTabGroups", "blocked");
user_pref("browser.ai.control.smartWindow", "blocked");
user_pref("browser.ai.control.translations", "blocked");
