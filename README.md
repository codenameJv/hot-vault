# Hot Vault

A Flutter application built with feature-first clean architecture.

## Getting Started

```bash
flutter pub get
flutter run
```

## Architecture

This project follows a **feature-first** architecture with clean code principles.

```
lib/
├── main.dart                 # Entry point
├── app/                      # App configuration
│   ├── app.dart              # Root widget
│   └── theme/                # Theming
├── core/                     # Core utilities
│   ├── constants/            # App constants
│   ├── errors/               # Error handling
│   ├── extensions/           # Dart extensions
│   ├── network/              # Network configuration
│   └── utils/                # Utilities
├── features/                 # Feature modules
│   └── [feature]/
│       ├── data/             # Data layer
│       │   ├── datasources/  # Remote/local data sources
│       │   ├── models/       # Data models
│       │   └── repositories/ # Repository implementations
│       ├── domain/           # Business logic
│       │   ├── entities/     # Business entities
│       │   ├── repositories/ # Repository contracts
│       │   └── usecases/     # Use cases
│       └── presentation/     # UI layer
│           ├── screens/      # Screen widgets
│           └── widgets/      # Feature widgets
└── shared/                   # Shared components
    ├── widgets/              # Reusable widgets
    └── styles/               # Shared styles
```

## Adding a New Feature

1. Create a new folder under `lib/features/[feature_name]/`
2. Add the three layers: `data/`, `domain/`, `presentation/`
3. Follow the existing structure for consistency

## Testing

Tests mirror the source structure:

```
test/
├── core/           # Core tests
├── features/       # Feature tests
└── widget_test.dart
```

Run tests:
```bash
flutter test
```
