# Optivote-PH

Lightweight mobile prototype for Optivote PH. This application helps users optimize their senatorial ballots based on legislative efficiency data.

## Project Structure

- `lib/` — Flutter source code
  - `main.dart` — App entry point and primary UI
  - `app_colors.dart` — Custom theme colors
  - `senator_card.dart` — UI component for displaying senator information
  - `optimizer_engine.dart` — Logic for the ballot optimization algorithm
- `assets/` — Data files (e.g., `senators_bill.csv`)
- `test/` — Widget and unit tests

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio / VS Code with Flutter extensions

## Getting Started

1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Run the application:**
    ```bash
    flutter run
    ```

## Features

- **Optimizer:** A Branch & Bound engine that suggests an optimal slate of 12 senators based on their "efficiency weight" (Passed Bills / Authored Bills).
- **Data-driven:** Uses real legislative data from `assets/senators_bill.csv`.
- **Dynamic Selection:** Manual selection with real-time feedback on ballot weight and count.
