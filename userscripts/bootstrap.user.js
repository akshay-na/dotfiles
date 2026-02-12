// ==UserScript==
// @name         Userscript Bootstrap Installer
// @namespace    dotfiles-bootstrap
// @version      2.0
// @description  Smart installer for all userscripts - only installs new or updated scripts
// @match        *://*/*
// @grant        GM_xmlhttpRequest
// @grant        GM_notification
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_installScript
// @run-at       document-idle
// ==/UserScript==

(function () {
  "use strict";

  const MANIFEST =
    "https://raw.githubusercontent.com/akshay-na/dotfiles/main/userscripts/manifest.json";
  const STORAGE_KEY = "dotfiles_installed_scripts";
  const LAST_RUN_KEY = "dotfiles_bootstrap_last_run";
  const CHECK_INTERVAL_MS = 60 * 60 * 1000; // 1 hour in milliseconds

  // Parse userscript header to extract metadata
  const parseScriptHeader = (scriptContent) => {
    const headerMatch = scriptContent.match(/\/\/ ==UserScript==([\s\S]*?)\/\/ ==\/UserScript==/);
    if (!headerMatch) return null;

    const header = headerMatch[1];
    const metadata = {};

    const patterns = {
      name: /@name\s+(.+)/i,
      version: /@version\s+(.+)/i,
      namespace: /@namespace\s+(.+)/i,
    };

    for (const [key, pattern] of Object.entries(patterns)) {
      const match = header.match(pattern);
      if (match) {
        metadata[key] = match[1].trim();
      }
    }

    return metadata;
  };

  // Get installed scripts from storage
  const getInstalledScripts = () => {
    try {
      return GM_getValue(STORAGE_KEY, {});
    } catch (e) {
      return {};
    }
  };

  // Save installed script info
  const saveInstalledScript = (name, version, url) => {
    try {
      const installed = getInstalledScripts();
      installed[name] = { version, url, installedAt: Date.now() };
      GM_setValue(STORAGE_KEY, installed);
    } catch (e) {
      console.warn("[Bootstrap] Failed to save script info:", e);
    }
  };

  // Check if script needs update
  const needsUpdate = (name, newVersion) => {
    const installed = getInstalledScripts();
    const installedScript = installed[name];

    if (!installedScript) {
      return true; // New script
    }

    // Compare versions (simple string comparison, can be improved with semver)
    return installedScript.version !== newVersion;
  };

  // Install script using GM_installScript (Tampermonkey) or fallback to URL
  const installScript = (scriptContent, url, metadata) => {
    // Try GM_installScript first (Tampermonkey)
    if (typeof GM_installScript !== "undefined") {
      try {
        GM_installScript(scriptContent);
        saveInstalledScript(metadata.name, metadata.version, url);
        return true;
      } catch (e) {
        console.warn("[Bootstrap] GM_installScript failed, using fallback:", e);
      }
    }

    // Fallback: create blob URL and open install page
    try {
      const blob = new Blob([scriptContent], { type: "text/javascript" });
      const blobUrl = URL.createObjectURL(blob);
      window.open(blobUrl, "_blank");
      // Note: We can't detect if user actually installed, so we'll save optimistically
      // User can re-run bootstrap to check for updates
      setTimeout(() => {
        URL.revokeObjectURL(blobUrl);
      }, 1000);
      return false; // Can't confirm installation
    } catch (e) {
      // Last resort: open original URL
      window.open(url, "_blank");
      return false;
    }
  };

  // Process a single script
  const processScript = async (scriptInfo) => {
    return new Promise((resolve) => {
      GM_xmlhttpRequest({
        method: "GET",
        url: scriptInfo.url,
        onload: (res) => {
          const scriptContent = res.responseText;
          const metadata = parseScriptHeader(scriptContent);

          if (!metadata || !metadata.name) {
            console.warn(`[Bootstrap] Failed to parse script: ${scriptInfo.url}`);
            resolve({ installed: false, reason: "parse_error" });
            return;
          }

          if (!needsUpdate(metadata.name, metadata.version || "unknown")) {
            console.log(`[Bootstrap] Script "${metadata.name}" is up to date`);
            resolve({ installed: false, reason: "up_to_date", name: metadata.name });
            return;
          }

          const installed = installScript(scriptContent, scriptInfo.url, metadata);
          resolve({
            installed: true,
            name: metadata.name,
            version: metadata.version,
            confirmed: installed,
          });
        },
        onerror: () => {
          console.error(`[Bootstrap] Failed to fetch script: ${scriptInfo.url}`);
          resolve({ installed: false, reason: "fetch_error" });
        },
      });
    });
  };

  // Get last run time
  const getLastRunTime = () => {
    try {
      return GM_getValue(LAST_RUN_KEY, 0);
    } catch (e) {
      return 0;
    }
  };

  // Save last run time
  const saveLastRunTime = () => {
    try {
      GM_setValue(LAST_RUN_KEY, Date.now());
    } catch (e) {
      console.warn("[Bootstrap] Failed to save last run time:", e);
    }
  };

  // Check if enough time has passed since last run
  const shouldRun = () => {
    const lastRun = getLastRunTime();
    const now = Date.now();
    return now - lastRun >= CHECK_INTERVAL_MS;
  };

  // Main installation process
  const installAllScripts = async () => {
    GM_notification({
      title: "Userscripts Installer",
      text: "Checking for updates...",
      timeout: 2000,
    });

    try {
      const manifestRes = await new Promise((resolve, reject) => {
        GM_xmlhttpRequest({
          method: "GET",
          url: MANIFEST,
          onload: resolve,
          onerror: reject,
        });
      });

      const data = JSON.parse(manifestRes.responseText);
      const results = [];

      // Process scripts sequentially to avoid overwhelming the browser
      for (const script of data.scripts) {
        const result = await processScript(script);
        results.push(result);
        // Small delay between scripts
        await new Promise((resolve) => setTimeout(resolve, 500));
      }

      const installed = results.filter((r) => r.installed);
      const upToDate = results.filter((r) => r.reason === "up_to_date");
      const failed = results.filter((r) => r.reason && r.reason !== "up_to_date");

      let message = "";
      if (installed.length > 0) {
        message += `Installed/Updated: ${installed.length}`;
      }
      if (upToDate.length > 0) {
        message += message ? ` | Up to date: ${upToDate.length}` : `All ${upToDate.length} scripts up to date`;
      }
      if (failed.length > 0) {
        message += message ? ` | Failed: ${failed.length}` : `Failed: ${failed.length}`;
      }

      GM_notification({
        title: "Userscripts Installer",
        text: message || "No scripts to install",
        timeout: 5000,
      });

      console.log("[Bootstrap] Installation summary:", {
        installed: installed.length,
        upToDate: upToDate.length,
        failed: failed.length,
        details: results,
      });

      // Save run time after successful completion
      saveLastRunTime();
    } catch (error) {
      GM_notification({
        title: "Userscripts Installer",
        text: "Failed to load manifest",
        timeout: 3000,
      });
      console.error("[Bootstrap] Error:", error);
    }
  };

  // Check and run if an hour has passed
  const checkAndRun = () => {
    if (shouldRun()) {
      console.log("[Bootstrap] Hourly check: Running installation check");
      installAllScripts();
    } else {
      const lastRun = getLastRunTime();
      const nextRun = lastRun + CHECK_INTERVAL_MS;
      const minutesUntilNext = Math.round((nextRun - Date.now()) / 60000);
      console.log(`[Bootstrap] Skipping check. Next run in ~${minutesUntilNext} minutes`);
    }
  };

  // Run check on page load if needed
  checkAndRun();

  // Set up interval for long-lived pages (runs every hour)
  setInterval(() => {
    checkAndRun();
  }, CHECK_INTERVAL_MS);

  // Expose function globally for manual triggering
  window.installUserscripts = installAllScripts;
})();
