// ==UserScript==
// @name         Tomorrowland Queue Watcher
// @namespace    dotfiles-tml-queue
// @version      2026.1.0
// @description  Notify when queue redirects or changes state
// @match        https://queue.prod.tomorrowland.com/*
// @grant        GM_notification
// @run-at       document-end
// ==/UserScript==

(function () {
  "use strict";

  const ORIGINAL_HOST = location.host;
  let triggered = false;

  const notify = (message) => {
    if (triggered) return;
    triggered = true;

    GM_notification({
      title: "Tomorrowland Queue Update",
      text: message,
      timeout: 0,
      onclick: () => window.focus(),
    });

    console.log("[Queue Watcher]", message);
  };

  /* Detect redirect away from queue */

  const checkRedirect = () => {
    if (location.host !== ORIGINAL_HOST) {
      notify("Redirected from queue page.");
    }
  };

  /* History hooks */

  const hookHistory = (method) => {
    const original = history[method];
    history[method] = function () {
      const result = original.apply(this, arguments);
      checkRedirect();
      return result;
    };
  };

  hookHistory("pushState");
  hookHistory("replaceState");

  window.addEventListener("popstate", checkRedirect);

  /* Poll fallback (meta refresh / hard redirect cases) */

  const interval = setInterval(() => {
    if (location.host !== ORIGINAL_HOST) {
      clearInterval(interval);
      notify("Redirect detected.");
    }
  }, 500);

  console.log("[Queue Watcher] Armed.");
})();
