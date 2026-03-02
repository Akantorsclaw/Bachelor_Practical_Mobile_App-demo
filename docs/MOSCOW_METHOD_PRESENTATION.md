# MoSCoW Presentation: MyLens_App_bachelor_practical

## Slide 1: Title
- **Project:** MyLens App Bachelor Practical
- **Method:** MoSCoW Prioritization
- **Goal:** Align implemented features with next-step roadmap

## Slide 2: Product Vision
- Deliver a branded mobile app for lens onboarding, registration, and digital passport access.
- Keep the system production-like: secure auth, user-linked data, and maintainable architecture.
- Prioritize stability first, then UX depth and operational features.

## Slide 3: Scope Baseline (Today)
- Flutter app with Firebase Auth + Firestore.
- Auth flow: Register -> GDPR -> Login -> Home.
- QR scan + parse into digital lens passport.
- User-linked lens storage and lens deletion.
- Branded UI system with centralized brand config and assets.

## Slide 4: MoSCoW Summary
- **Must Have:** Core user journey, data integrity, security-critical behavior.
- **Should Have:** High-value polish and near-term operational improvements.
- **Could Have:** Nice-to-have enhancements that improve UX/insight but are not critical.
- **Won't Have (for now):** Out-of-scope features for current practical timeline.

## Slide 5: Must Have (Implemented)
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

## Slide 6: Must Have (Remaining Gaps)
- Production Firestore rules deployment/verification for all lens writes/deletes in every environment.
- Final device-level smoke test matrix (Android + iOS real devices).
- Final iOS signing/provisioning completion in Apple Developer account.

## Slide 7: Should Have (Near-Term)
- Persist **Notification Settings** to backend instead of local-only state.
- Implement **Change Optician** flow (currently placeholder).
- Add profile edit success/error states with richer inline guidance.
- Add better empty states and retry states for network-dependent screens.
- Add structured analytics events for key flow milestones.

## Slide 8: Could Have (Future Enhancements)
- Offline caching and queued sync for lens data.
- Multi-language localization from mapping sheet assets.
- Export/share Digital Lens Passport (PDF or secure link).
- Better onboarding tutorial for first-time users.
- Accessibility pass (dynamic text scaling, contrast presets, screen-reader labels).
- Advanced filter/sort/search in lens list.

## Slide 9: Won't Have (This Practical Phase)
- Social login providers (Google/Apple/Facebook).
- Full admin portal for optician operations.
- Complex recommendation engine / AI personalization.
- Multi-tenant enterprise management features.
- Full web backend console implementation.

## Slide 10: Prioritization Rationale
- **Risk-first:** Protect account/data flow and legal consent handling.
- **Value-first:** Complete lens registration + passport consumption path.
- **Effort-aware:** Defer high-effort platform expansions until core flow is stable.
- **Maintainability:** Keep modular architecture and test/analyze checks on each change.

## Slide 11: Delivery Plan (Incremental)
1. Close Must-Have gaps (rules/signing/smoke test).
2. Implement Should-Have backend-connected settings and optician flow.
3. Add Could-Have UX and data enhancements based on test feedback.

## Slide 12: Success Metrics
- Registration completion rate.
- QR-to-passport completion rate.
- Lens save success rate.
- Consent withdrawal completion without app errors.
- Crash-free session rate.
- Mean time to recover from Firebase/config issues.

## Slide 13: Risks and Dependencies
- Firebase project config mismatches (bundle ID/package ID).
- Firestore security rule misconfiguration.
- iOS certificate/provisioning dependencies.
- External QR payload quality and parameter completeness.

## Slide 14: Current Decision Request
- Validate MoSCoW categories with supervisor/stakeholders.
- Freeze Must-Have acceptance criteria.
- Approve next sprint on Should-Have items:
  - Notification settings persistence
  - Change optician flow
  - Additional UX reliability states

---

## Speaker Notes (Optional)
- Use Slides 5–6 to show what is already production-like vs what still blocks release readiness.
- Use Slides 7–8 to justify roadmap decisions with effort/value tradeoffs.
- Use Slide 12 to show measurable project maturity, not only implemented screens.
