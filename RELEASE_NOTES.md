# Release Notes

## v1.1.0 — 2026-05-26
- Update the optimization to always result 12 candidates
- Those exceed the 9.0 cap are highlighted in yellow
- Added view slate button
- Update about tab 

## v1.0.0 — 2026-05-25
- Added the icon and chnage the app label

## v0.1.4 — 2026-05-23 - 2026-05-24
- Added profile page for each senator
- Fixed overflow

## v0.1.3 — 2026-05-20
- **Auto-Applying Priorities:** Removed the "Apply Priorities" button; sector selections are now applied instantly and persist across tabs.

## v0.1.2 — 2026-05-20
Summary 
- Added exclude senator to optimizer

Next step 
- profile for each senator
- other updates

## v0.1.1 — 2026-05-12 - 2026-05-19

Summary
- Full migration from legacy HTML/CSS/JS to a Flutter mobile prototype.
- Implementation of Sector-Based Prioritization.
- Complete UI/UX redesign for mobile experience.

Notable details
- **Legacy Cleanup:** Removed all old HTML, CSS, and JS files. The project is now a dedicated Flutter application.
- **Bill Sectors:** Users can now select specific committee priorities (e.g., Agriculture & Environment, Education, Science & Culture). The optimization engine dynamically adjusts senator "Value" (V) based on these choices.
- **Redesigned Sectors UI:** Implemented a modern grid-based selection screen with custom icons and descriptive subtitles.
- **Expanded About Section:** Added detailed information about the project mission (combatting disinformation), the Branch & Bound algorithm, the Knapsack Problem, and the development team (PUP BSCS 2-6).
- **Data Persistence:** Migrated legislative data to a local `assets/senators_bill.csv` for faster, offline access.

---

## v0.1.0 — 2026-05-08

Summary
- Initial develoment (v0.1.0) of Optivote-PH frontend and proxy.

Notable details
- Seems like the Open Congress API data are kulang pa or incorrectly updated 'yung mga data (i think). 