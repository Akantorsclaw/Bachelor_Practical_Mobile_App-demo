# CLAUDE.md — Bachelor_Practical_Mobile_App

This file configures Claude Code's behaviour for this project.
It is read automatically at the start of every session.

---

## Mandatory: Plan Before Every Assignment

**Before writing any code or modifying any file, always present a plan and wait for explicit approval.**

The plan must include:

1. **Assignment summary** — restate the goal in your own words to confirm shared understanding.
2. **Codebase analysis** — list the relevant files and modules you have inspected.
3. **Scope of changes** — enumerate every file that will be created, modified, or deleted.
4. **Approach** — describe the implementation strategy and key decisions.
5. **Risks / open questions** — flag anything that could disrupt existing behaviour, break the B2B2C constraint, or require a design decision.
6. **Validation steps** — state which checks will be run (`flutter analyze`, `flutter test`, runtime smoke test).

Do not proceed until the user responds with an explicit approval (e.g. "looks good", "go ahead", "approved").

---

## Project Context

- **Stack:** Flutter / Dart, Firebase Auth, Cloud Firestore, mobile_scanner, flutter_svg
- **Targets:** Android + iOS
- **Architecture:** `lib/app`, `lib/auth`, `lib/core`, `lib/core/screens`, `lib/services`, `lib/models`, `lib/shared`, `lib/branding`
- **Docs:** `docs/` — keep `BACHELOR_PRACTICAL_WORKFLOW.md`, `ARCHITECTURE_OVERVIEW.md`, `FUNCTIONS_EXPLAINED.md`, and `DESIGN_WORKFLOW.md` up to date after each assignment.

---

## Core Constraints

- **B2B2C model:** The optician is a mandatory intermediary. No flow may bypass the optician role. All new features must preserve optician context in lens registration, passport, and review flows.
- **Minimal disruption:** Changes must be targeted. Do not refactor code outside the assignment scope.
- **No logic changes in structural tasks:** Pure structural or documentation assignments must not alter runtime behaviour.
- **Branding system:** All colours, assets, and chrome must go through `lib/branding`. Never hardcode colours or asset paths in screen files.

---

## Workflow (per assignment)

1. Read and restate the requirement.
2. Analyse the relevant parts of the codebase.
3. Present the full plan — wait for approval.
4. Implement in small, reviewable steps.
5. Run `flutter analyze` and `flutter test` after every meaningful change.
6. Update the relevant `docs/` files.
7. Confirm a checkpoint is ready if the stable-checkpoint checklist is met.

---

## Checkpoint Commits

Before starting any assignment, create a checkpoint commit so the stable state can be restored at any time:

```
git add -A
git commit -m "checkpoint: <short description> (pre-<assignment number>)"
```

The commit SHA should be noted so the user can roll back with `git reset --hard <sha>` if needed.

---

## Firestore Seed Scripts

Admin seed scripts live in `scripts/` and use the `firebase-admin` Python SDK.

- The virtual environment is at `scripts/.venv/` — **never commit it**.
- Service-account key files (`scripts/*.json`) — **never commit them** (covered by `.gitignore`).
- To run a seed script: `cd scripts && .venv/bin/python3 <script>.py`
- New seed scripts follow the pattern established in `scripts/seed_news.py` and the earlier opticians seeder.

---

## Checkpoint Checklist (before tagging)

- [ ] `flutter analyze` passes with zero issues
- [ ] `flutter test` passes
- [ ] Main flow manually smoke-tested on emulator or device
- [ ] `docs/BACHELOR_PRACTICAL_WORKFLOW.md` updated with assignment log entry
- [ ] Checkpoint commit created before the assignment started
- [ ] Commit message clearly describes scope

---

## Assignment Log Updates

After each completed assignment, append an entry to `docs/BACHELOR_PRACTICAL_WORKFLOW.md` under **Section 10 — Assignment Log** in the following format:

```
### Assignment <N>

- <One-line goal summary>.
- Output:
  - <Change 1>
  - <Change 2>
  - ...
```
