# MoSCoW Presentation: Bachelor_Practical_Mobile_App

## Title
- **Project:** MyLens App Bachelor Practical
- **Method:** MoSCoW Prioritization
- **Goal:** Align implemented features with next-step roadmap

---

## Product Vision
- Deliver a branded mobile app for lens onboarding, registration, and digital passport access.
- Keep the system production-like: secure auth, user-linked data, and maintainable architecture.
- Honour the **B2B2C model**: the optician is a mandatory intermediary — every flow preserves the optician relationship and does not enable pure self-service bypass.
- Prioritize stability first, then UX depth and operational features.

---

## Scope Baseline (Assignment 012)
- Flutter app with Firebase Auth + Firestore.
- Auth flow: Register → GDPR consent → Login → Home.
- QR scan + parse into digital lens passport.
- User-linked lens storage and lens deletion.
- Rating and review workflow (lens selection, Firestore-backed upsert).
- Multi-brand UI system (HOYA + SEIKO) with runtime-switchable brand config.
- Privacy/GDPR screen with Firestore preference persistence.
- Accessibility polish (dynamic text scaling, contrast, screen-reader labels).
- Modular screen architecture: shell (~370 lines) + 8 dedicated screen files.

---

## MoSCoW Summary
- **Must Have:** Core user journey, data integrity, security-critical behaviour.
- **Should Have:** High-value near-term improvements, B2B2C optician integration.
- **Could Have:** Enhancements that improve UX, content depth, or operational insight.
- **Won't Have — This Phase:** Deferred but planned future extensions.
- **Won't Have — Out of Scope:** Outside the practical project boundary.

---

## Must Have ✓ Implemented

- Firebase email/password authentication.
- Firestore user profile and session state handling.
- GDPR consent step in onboarding.
- Consent withdrawal flow with account deactivation and forced return to login.
- Password reset flow.
- QR scanner integration (`mobile_scanner`).
- Digital Lens Passport rendering (multiple sections/tabs).
- User-linked lens persistence (`users/{uid}/lenses/{lensId}`).
- Lens deletion capability.
- Logout confirmation and native back-navigation handling.
- iOS/Android app configuration and Firebase wiring.
- Rating/review workflow with Firestore-backed upsert (`users/{uid}/reviews/{reviewId}`).
- Multi-brand runtime switching (HOYA + SEIKO) with centralized brand config.
- Privacy/GDPR screen with Firestore preference persistence.
- Accessibility pass: dynamic text scaling, contrast presets, screen-reader labels.
- Core shell split: modular screen architecture (Assignment 012).

## Must Have — Remaining Gaps

- Production Firestore security rules deployment and verification across all environments.
- Final device-level smoke test matrix (Android + iOS real devices).
- Final iOS signing/provisioning completion in Apple Developer account.

---

## Should Have (Near-Term)

- **Find Optician flow** — replaces placeholder "Change Optician"; includes geolocation-based search, list/map toggle, and optician assignment to user profile. Fulfils B2B2C constraint (Assignment 013).
- **Optician context in lens flows** — optician name surfaced on lens registration, lens passport, and review attribution.
- **Persist Notification Settings** to backend instead of local-only state.
- **Better empty and error states** across all network-dependent screens.
- **Structured analytics events** for key flow milestones (registration, QR scan, lens save, review submit).
- **Profile edit success/error states** with richer inline guidance.

---

## Could Have (Future Enhancements)

- **Push notifications** — warranty reminders, rating prompts, frame adjustment alerts, contact lens refill reminders.
- **Email confirmation** on registration for improved account security.
- **Review digest for optician** — periodic email report of lens and service ratings generated for the assigned optician.
- **Emergency contact info** — quick access to optician contact details for lens-related urgencies.
- **User care guides** — in-app lens care instructions and cleaning manuals per lens type.
- **Export/share Digital Lens Passport** — PDF or secure shareable link.
- **Offline caching and queued sync** for lens data.
- **Multi-language localisation** from mapping sheet assets.
- **Advanced filter/sort/search** in lens list.
- **Better onboarding tutorial** for first-time users.

---

## Won't Have — This Phase (Planned Future Extension)

- **Optician-facing dashboard portal** — role-based optician view with lens ratings, service ratings, and review overview. Designed (Figma Make: `Hoya_Branded_app.make`); deferred due to scope. Represents the full B2B2C extension vision.
  - Requires: Firebase Auth custom claims, new service review data model with sub-dimensions, separate navigation shell.
  - Scoped MVP defined: KPI header + recent reviews + per-lens rating cards + basic service score.

---

## Won't Have — Out of Scope

- Social login providers (Google/Apple/Facebook).
- Complex recommendation engine / AI personalisation.
- Multi-tenant enterprise management features.
- Full web backend console implementation.
- Style consultation (Stilberatung) features.

---

## B2B2C Alignment

The B2B2C constraint (BACHELOR_PRACTICAL_WORKFLOW.md §1.1) requires that the optician is never bypassed — they are a mandatory intermediary in all product and service flows.

**Fulfilled in consumer app (Phase 1):**
- Optician assigned to user profile via Find Optician flow.
- Optician context surfaced in lens registration, lens passport, and review attribution.
- Product decisions favour customer + optician collaboration over pure self-service.

**Planned extension (Phase 2 — Optician Portal):**
- Optician-facing dashboard giving opticians direct visibility into ratings and customer activity.
- Gives opticians a genuine value proposition to adopt and recommend the app.
- Documented as Won't Have — This Phase; designs available in `Hoya_Branded_app.make`.

---

## Prioritisation Rationale

- **Risk-first:** Protect account/data flow and legal consent handling.
- **Value-first:** Complete lens registration + passport consumption path.
- **B2B2C-first:** All flows preserve the optician relationship; no pure self-service bypass.
- **Effort-aware:** Defer high-effort platform expansions until core consumer flow is stable.
- **Maintainability:** Modular architecture with `flutter analyze` and test checks on each change.

---

## Delivery Plan (Incremental)

1. Close Must-Have gaps (Firestore rules / iOS signing / device smoke test).
2. Assignment 013: Find Optician + optician context in lens and review flows (B2B2C fulfilment).
3. Should-Have: notification settings persistence, empty/error states, analytics.
4. Could-Have: push notifications, email confirmation, care guides, optician review digest.
5. Future: optician-facing portal (Phase 2 B2B2C extension).

---

## Success Metrics

- Registration completion rate.
- QR-to-passport completion rate.
- Lens save success rate.
- Review submission rate.
- Optician assignment rate (users with an assigned optician).
- Consent withdrawal completion without app errors.
- Crash-free session rate.
- Mean time to recover from Firebase/config issues.

---

## Risks and Dependencies

- Firebase project config mismatches (bundle ID/package ID).
- Firestore security rule misconfiguration.
- iOS certificate/provisioning dependencies.
- External QR payload quality and parameter completeness.
- Geolocation permissions on Android/iOS for Find Optician flow.

---

## Current Decision Request

- Validate updated MoSCoW categories with supervisor/stakeholders.
- Freeze Must-Have acceptance criteria.
- Approve Assignment 013 scope: Find Optician + B2B2C optician context.
- Confirm optician dashboard deferral as documented future scope.

---