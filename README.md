# Optivote-PH

Lightweight mobile prototype for Optivote PH. This application helps users optimize their senatorial ballots based on legislative efficiency data.

## Project Structure

```text
optivote_ph_mobile_prototype/
├── assets/                       # App assets
│   └── senators_bill.csv         # Legislative data source
├── lib/                          # Flutter source code
│   ├── main.dart                 # App entry point & primary UI
│   ├── app_colors.dart           # Custom theme colors
│   ├── senator_card.dart         # UI component for displaying senators
│   └── optimizer_engine.dart     # B&B and Shaker Sort logic
├── test/                         # Widget and unit tests
├── pubspec.yaml                  # Project dependencies & assets config
└── README.md                     # Project overview and setup guide
```

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

- **Sector Selection:** Choose specific legislative committees to tailor productivity data.
- **Optimizer:** A Branch & Bound engine that suggests an optimal slate of 12 senators based on their "efficiency weight".
- **Data-driven:** Uses real legislative data from `assets/senators_bill.csv`.
- **Dynamic Selection:** Manual selection with real-time feedback on ballot weight and count.
