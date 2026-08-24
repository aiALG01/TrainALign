(function () {
  "use strict";

  /* ---------- Header-Höhe als CSS-Variable ----------
     Der Header ist position:fixed (siehe style.css für den Grund), daher
     braucht der Rest der Seite ein passendes Offset. Statt einer festen
     Zahl wird die tatsächliche Höhe gemessen, damit z. B. Zeilenumbrüche
     im Wortmark bei sehr kleinen Displays nicht zu Überlappungen führen.
  */
  var siteHeader = document.querySelector(".site-header");

  function setHeaderHeight() {
    if (siteHeader) {
      document.documentElement.style.setProperty("--header-height", siteHeader.offsetHeight + "px");
    }
  }

  setHeaderHeight();
  window.addEventListener("resize", setHeaderHeight);

  /* ---------- Mobiles Menü ---------- */
  var navToggle = document.getElementById("navToggle");
  var primaryNav = document.getElementById("primaryNav");

  function closeNav() {
    primaryNav.removeAttribute("data-open");
    navToggle.setAttribute("aria-expanded", "false");
  }

  function toggleNav() {
    var isOpen = primaryNav.getAttribute("data-open") === "true";
    if (isOpen) {
      closeNav();
    } else {
      primaryNav.setAttribute("data-open", "true");
      navToggle.setAttribute("aria-expanded", "true");
    }
  }

  if (navToggle && primaryNav) {
    navToggle.addEventListener("click", toggleNav);

    primaryNav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", closeNav);
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        closeNav();
      }
    });
  }

  /* ---------- Smooth Scroll für Anker-Links ---------- */
  document.querySelectorAll('a[href^="#"]').forEach(function (link) {
    link.addEventListener("click", function (event) {
      var targetId = link.getAttribute("href");
      if (!targetId || targetId === "#") {
        return;
      }
      var target = document.querySelector(targetId);
      if (!target) {
        return;
      }
      event.preventDefault();
      target.scrollIntoView({ behavior: "smooth", block: "start" });
      target.setAttribute("tabindex", "-1");
      target.focus({ preventScroll: true });
    });
  });

  /* ---------- Dezentes Scroll-Reveal ----------
     Inhalte sind per Default (siehe style.css) sichtbar, damit ohne JS,
     bei blockiertem Skript oder in einem Headless-Renderer nie eine
     leere Sektion ausgeliefert wird. Erst wenn dieser Code läuft UND
     "prefers-reduced-motion" nicht aktiv ist, wird die Hidden-then-
     Fade-in-Choreografie über die Klasse "reveal-armed" auf <html>
     scharf geschaltet; danach übernimmt IntersectionObserver das
     Einblenden pro Element. */
  var revealTargets = document.querySelectorAll("[data-reveal]");
  var prefersReducedMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if ("IntersectionObserver" in window && revealTargets.length && !prefersReducedMotion) {
    document.documentElement.classList.add("reveal-armed");

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15, rootMargin: "0px 0px -60px 0px" }
    );

    revealTargets.forEach(function (el) {
      observer.observe(el);
    });
  }

  /* ---------- Warteliste (Frontend-only) ----------
     Es gibt noch kein Backend: Das Formular sendet aktuell nichts,
     sondern bestätigt lokal im Browser. Sobald ein Endpunkt existiert
     (z. B. eine Supabase-Tabelle für die Warteliste), hier den echten
     Request ergänzen.
  */
  var waitlistForm = document.getElementById("waitlistForm");
  var waitlistMessage = document.getElementById("waitlistMessage");

  if (waitlistForm && waitlistMessage) {
    waitlistForm.addEventListener("submit", function (event) {
      event.preventDefault();

      var emailInput = document.getElementById("waitlistEmail");
      var email = emailInput.value.trim();
      var isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

      if (!isValid) {
        waitlistMessage.textContent = "Bitte eine gültige E-Mail-Adresse eingeben.";
        waitlistMessage.setAttribute("data-state", "error");
        emailInput.focus();
        return;
      }

      waitlistMessage.removeAttribute("data-state");
      waitlistMessage.textContent = "Danke! Wir melden uns, sobald es losgeht.";
      waitlistForm.reset();
    });
  }
})();
