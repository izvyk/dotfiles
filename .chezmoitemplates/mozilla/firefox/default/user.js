// Load chrome/userChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Unload tabs not used for 10+ min when available RAM drops under 10%. Off by
// default on Linux, and the default 5% leaves too little time before swapping
// gets heavy.
user_pref("browser.tabs.unloadOnLowMemory", true);
user_pref("browser.low_commit_space_threshold_percent", 10);
