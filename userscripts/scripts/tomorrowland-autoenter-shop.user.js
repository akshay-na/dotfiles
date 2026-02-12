// ==UserScript==
// @name         Tomorrowland Auto Enter Shop
// @namespace    dotfiles-tml-autoenter
// @version      2026.1.0
// @description  Automatically clicks the "Enter Shop" button when available
// @match        https://my.tomorrowland.com/event/*
// @run-at       document-end
// ==/UserScript==

(function () {
  const LABEL = "enter shop";

  const findButton = () =>
    [...document.querySelectorAll("button")].find(
      (b) => b.textContent.trim().toLowerCase() === LABEL
    );

  const isEnabled = (btn) =>
    !btn.disabled &&
    btn.getAttribute("aria-disabled") !== "true" &&
    !btn.classList.contains("disabled");

  const tryClick = () => {
    const btn = findButton();
    if (!btn) return false;

    if (isEnabled(btn)) {
      console.log("[TM] Enter Shop enabled → clicking");
      btn.click();
      return true;
    }
    return false;
  };

  const observer = new MutationObserver(() => {
    if (tryClick()) observer.disconnect();
  });

  window.addEventListener("DOMContentLoaded", () => {
    if (tryClick()) return;

    observer.observe(document.documentElement, {
      attributes: true,
      childList: true,
      subtree: true,
    });
  });
})();
