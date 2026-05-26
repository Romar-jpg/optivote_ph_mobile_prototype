# Optivote-PH

A lightweight Flutter mobile prototype that helps Filipino voters optimize their senatorial ballots using real legislative efficiency data and mathematical algorithms.

## Project Structure

```text
optivote_ph_mobile_prototype/
├── assets/
│   ├── senators_bill.csv         # Legislative data source (bills authored & passed per sector)
│   ├── OVPH-transparent.png      # App logo (dark backgrounds)
│   └── OVPH-white.png            # App logo (launcher icon)
├── lib/                          # Flutter source code
│   ├── main.dart                 # App entry point, primary UI, and optimizer orchestration
│   ├── app_colors.dart           # Centralized brand & UI color palette
│   ├── senator_card.dart         # Animated senator card widget (selected / excluded / recommended states)
│   ├── senator_profile.dart      # Full senator profile screen
│   └── optimizer_engine.dart     # Branch & Bound optimizer + Shaker Sort
├── test/
│   └── widget_test.dart          # Smoke tests for AppBar and loading state
├── pubspec.yaml                  # Dependencies & asset configuration
├── ALGORITHM_EXPLANATION.md      # Deep-dive: B&B algorithm, two-pass slate completion, Slate Viewer
├── SECTORS_SELECTION_EXPLANATION.md  # Multi-sector V recalculation logic & flowcharts
├── RELEASE_NOTES.md              # Version history
└── README.md                     # This file
```

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.11.5`)
- Android Studio / VS Code with Flutter & Dart extensions

## Getting Started

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the application:**
   ```bash
   flutter run
   ```

3. **Run tests:**
   ```bash
   flutter test
   ```

## Features

- **Sector Selection:** Choose from 7 legislative focus areas (Social Services, Education, Economy, Infrastructure, Agriculture, Justice, Governance) to tailor each senator's productivity score ($V$) to your priorities.
- **Branch & Bound Optimizer:** A two-pass optimization engine that always produces a complete 12-senator ballot:
  - **Pass 1 (Constrained):** Finds the optimal slate within the 9.0 inefficiency weight cap.
  - **Pass 2 (Unconstrained):** If Pass 1 yields fewer than 12 candidates, a secondary pass completes the slate with the best remaining picks, highlighted with a **gold border**.
- **Shaker Sort Ranking:** The final slate is sorted from highest to lowest productivity value using Bidirectional Bubble Sort.
- **Slate Viewer:** Tap the list icon (⊟) in the top-right AppBar to open a scrollable, ranked summary of your 12 selected senators, with gold-dot indicators for recommended picks.
- **Senator Profiles:** Long-press any senator card to view their detailed legislative profile.
- **Exclusion List:** Long-press to exclude specific senators from the optimizer entirely.
- **Dynamic Selection:** Manual tap-to-select with real-time feedback on ballot weight (`W`) and candidate count.
- **Data-driven:** All data sourced from real legislative records in `assets/senators_bill.csv`.

## Documentation

| File | Description |
|---|---|
| [ALGORITHM_EXPLANATION.md](./ALGORITHM_EXPLANATION.md) | Full technical breakdown of the B&B optimizer, two-pass slate completion, and Slate Viewer UI |
| [SECTORS_SELECTION_EXPLANATION.md](./SECTORS_SELECTION_EXPLANATION.md) | How sector selection recalculates $V$ and interacts with the two-pass optimizer |
| [RELEASE_NOTES.md](./RELEASE_NOTES.md) | Version history and changelog |
