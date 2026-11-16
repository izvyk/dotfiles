// Firefox re-applies this file on every start: changing one of these in
// Settings or about:config only lasts until the next restart.
// Enterprise policies (telemetry, password manager, studies) live in
// nixos-config, programs.firefox.policies, and only apply on buratino.

// --- Customization -----------------------------------------------------------

// Load chrome/userChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// --- Memory ------------------------------------------------------------------

// Unload tabs not used for 10+ min when available RAM drops under 10%. Off by
// default on Linux, and the default 5% leaves too little time before swapping
// gets heavy.
user_pref("browser.tabs.unloadOnLowMemory", true);
user_pref("browser.low_commit_space_threshold_percent", 10);

// --- Behavior ----------------------------------------------------------------

user_pref("browser.startup.page", 3);                  // restore last session
user_pref("browser.tabs.warnOnClose", true);           // confirm closing a window with several tabs
user_pref("browser.tabs.inTitlebar", 1);               // tabs in the titlebar, no system titlebar
user_pref("browser.toolbars.bookmarks.visibility", "never");
user_pref("sidebar.visibility", "hide-on-close");
// Sidebar holds only the AI chatbot (Ctrl+Alt+X), with Claude as provider.
user_pref("sidebar.main.tools", "aichat");
user_pref("browser.ml.chat.provider", "https://claude.ai/new");
user_pref("findbar.highlightAll", true);
user_pref("accessibility.typeaheadfind.flashBar", 0);  // don't flash the find bar
user_pref("full-screen-api.warning.timeout", 0);       // no "site is now fullscreen" notice
user_pref("mousewheel.with_alt.action", 5);            // Alt+wheel zooms
user_pref("ui.key.menuAccessKeyFocuses", false);       // a lone Alt doesn't focus the menu bar
user_pref("devtools.toolbox.host", "right");

// --- Language and fonts -------------------------------------------------------

user_pref("intl.locale.requested", "en-US,ru,de");     // UI language order; langpacks come from the NixOS policy
user_pref("intl.regional_prefs.use_os_locales", true); // dates and numbers in the OS format
user_pref("font.language.group", "x-cyrillic");
user_pref("font.default.x-western", "sans-serif");
user_pref("font.default.x-cyrillic", "sans-serif");
// "Apple Emoji" is the renamed Apple Color Emoji from nixos-config
// (hosts/buratino/apple-emoji.nix). Missing names are skipped.
user_pref("font.name-list.emoji", "Apple Emoji, Noto Color Emoji, Twemoji Mozilla");

// --- Media -------------------------------------------------------------------

user_pref("media.eme.enabled", true);                  // DRM, for Netflix, Spotify and the like
{{- if eq .chezmoi.hostname "buratino" }}
// buratino's Ryzen 4600U (Renoir) has no AV1 hardware decoder. With AV1 off,
// YouTube serves VP9, which it decodes in hardware.
user_pref("media.av1.enabled", false);
{{- end }}

// --- Privacy and security -------------------------------------------------------

// Don't load or connect to things before they're clicked: rel=next/prefetch
// links, DNS lookups for links on the page, and connections on link hover.
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.http.speculative-parallel-limit", 0);

// Send the Global Privacy Control signal ("don't sell or share my data").
user_pref("privacy.globalprivacycontrol.enabled", true);

// HTTPS-Only: show a warning page instead of silently falling back to plain
// HTTP. Private IPs such as the router aren't upgraded; other HTTP-only sites
// need one click on "Continue to HTTP Site".
user_pref("dom.security.https_only_mode", true);

// No Mozilla studies, no add-on or feature recommendations.
user_pref("app.shield.optoutstudies.enabled", false);
// Keep rollouts (the default): Mozilla can switch off a broken or vulnerable
// feature remotely before the fixed version reaches nixpkgs. Explicit, so a
// false from an earlier user.js doesn't stick in prefs.js.
user_pref("nimbus.rollouts.enabled", true);
user_pref("browser.discovery.enabled", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);

// No built-in VPN ("IP Protection"). A Nimbus rollout or an in-browser
// message can switch it on behind our back; user.js turns it off again on the
// next start. optedOut also hides the toolbar button.
user_pref("browser.ipProtection.enabled", false);
user_pref("browser.ipProtection.optedOut", true);
user_pref("browser.ipProtection.blockIPProtectionCallouts", true);
user_pref("browser.vpn_promo.enabled", false);             // Mozilla VPN ads

// --- New tab page ----------------------------------------------------------------

user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
// No "Recent activity" section (the default; explicit so an earlier true
// doesn't stick in prefs.js)
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.bookmarks.showMobileBookmarks", false);
