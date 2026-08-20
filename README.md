# xBudget

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-40%20Passed-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

A privacy-focused, offline-first personal budgeting and expense tracking application built with Flutter. **xBudget** automatically parses transaction SMS messages directly on your device, tracks your real-time bank balance, categorizes expenses, and provides financial insights without sending your sensitive data to the cloud.

---

## Description

- **What was your motivation?**  
  Managing personal finances is critical, but existing budgeting tools often create friction: they either require tedious manual logging for every small purchase or compromise user privacy by requiring bank credentials and transmitting financial statements to remote third-party servers.

- **Why did you build this project?**  
  We built **xBudget** to give users total control and immediate visibility over their spending and bank balances without sacrificing privacy. By leveraging on-device SMS parsing, users get the convenience of automated expense tracking with zero external cloud dependencies.

- **What problem does it solve?**  
  - Eliminates manual transaction entry by automatically extracting amounts, merchants, categories, and account balances from incoming banking SMS notifications.
  - Keeps financial data 100% private and offline on the user's device.
  - Automatically deduplicates recurring or re-synced notifications using cryptographic hashing.
  - Provides a single dashboard to monitor current available balances, monthly spending, and category breakdowns.

- **What did you learn?**  
  - Implementing **Clean Architecture** in Flutter with pure domain entities, repositories, data sources, and presentation layers.
  - Designing an extensible **Strategy Pattern** for bank-specific SMS parsing (`BankParserStrategy`), making it trivial to add support for new banks.
  - Handling regular expressions and heuristic-based categorizers for Indian banking and UPI SMS formats.
  - Deterministic deduplication using SHA-256 hashes of transaction metadata.
  - Writing comprehensive unit and widget tests in Flutter.

---

## Table of Contents

- [Features](#features)
- [Architecture & Tech Stack](#architecture--tech-stack)
- [Installation](#installation)
- [Usage](#usage)
- [Tests](#tests)
- [How to Contribute](#how-to-contribute)
- [Credits](#credits)
- [License](#license)

---

## Features

- **Automated On-Device SMS Parsing**:
  - Modular parser architecture using the Strategy Pattern (`IciciParserStrategy` built-in, extensible to HDFC, SBI, Axis, etc.).
  - Fast-pass guard clauses to ignore OTPs, marketing SMS, and non-transactional messages.
  - Robust regex extraction for debit, credit, card spends, and UPI transactions.

- **Real-Time Balance Tracking**:
  - Automatically captures latest available balance from transaction SMS.
  - Interactive **Note Balance** modal for manual adjustments and quick adjustment chips (`+₹500`, `+₹1,000`, `+₹5,000`, `-₹500`, `-₹1,000`).
  - Source tracking (auto SMS vs manual update) with clear timestamp indicators.

- **Intelligent Category Mapping**:
  - Multi-tier categorization engine covering Food, Groceries, Transport, Shopping, Bills, Entertainment, Health, Rent, Investment, Salary, and P2P Transfers.
  - Support for custom user-defined merchant category mapping rules.
  - P2P transfer identification for manual review and tagging.

- **Deterministic Deduplication**:
  - Generates SHA-256 hashes from transaction attributes (`amount`, `merchant`, `date`, `rawMessage`) to prevent duplicate records during incremental syncs.

- **100% Offline & Private**:
  - No internet permissions required for financial operations; all data resides securely in local storage.

- **Sample Data Ingestion for Testing**:
  - Built-in sample SMS generator allowing instant testing of all features across emulators, simulators, iOS, and Web without needing a physical SIM card.

---

## Architecture & Tech Stack

```
lib/
├── core/
│   ├── constants/       # App preferences & storage keys
│   ├── services/        # SMS sync coordinator & inbox queries
│   └── utils/           # Parser strategies, categorizers, data models
│       └── strategies/  # Bank-specific parsers (ICICI, etc.)
├── data/
│   ├── datasources/     # Local storage data sources (SharedPreferences)
│   ├── models/          # Data transfer models & JSON serialization
│   └── repositories/    # Repository implementations
├── domain/
│   ├── entities/        # Pure domain entities (TransactionEntity, BudgetCategory)
│   └── repositories/    # Abstract repository contracts
└── presentation/
    └── screens/         # UI screens, dashboards, and modal sheets
```

- **Framework**: [Flutter](https://flutter.dev/) (SDK `^3.10.0`)
- **Language**: [Dart](https://dart.dev/)
- **State & Storage**: `shared_preferences`
- **SMS Reading**: `flutter_sms_inbox`, `permission_handler`
- **Security & Hashing**: `crypto` (SHA-256)

---

## Installation

Follow these steps to set up the development environment and run **xBudget** locally:

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.10.0` or later)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extensions
- Android device or Android Emulator (API 26+) for SMS features, or any simulator/web browser for sample data mode

### Step-by-Step Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/xbudget.git
   cd xbudget
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup**:
   ```bash
   flutter doctor
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

> **Note for Android Users:** When prompted on first launch or during SMS sync, grant the **SMS Permission** to allow the app to read local bank transaction notifications.

---

## Usage

### 1. Synchronizing Transactions
- Tap the **Sync SMS** icon (`sync`) in the top app bar to read eligible bank messages from the past 60 days. Subsequent syncs will incrementally ingest only new messages.
- On non-Android platforms (or emulators without SMS), tap the **Flash** icon (`flash_on`) to load realistic sample banking SMS data.

### 2. Updating Current Balance
- Tap **Note Balance** or the balance card to view your available funds.
- Enter a specific balance or use the **Quick Adjustments** chips (`+₹500`, `+₹1,000`, etc.) to update your balance.

### 3. Categorizing & Reviewing
- Tap any transaction card to open the **Transaction Details** bottom sheet.
- Inspect the raw SMS text, change the assigned category, or add custom notes.
- Filter transactions by category using the interactive category chips on the dashboard.

### Screenshots

To add screenshots, place image files in `assets/images/` and reference them:

```md
![Dashboard](assets/images/dashboard.png)
![Balance Modal](assets/images/balance_modal.png)
```

---

## Tests

xBudget includes a comprehensive suite of unit and widget tests covering parser strategies, deduplication, categorization heuristics, preferences, and UI interactions.

### Running Tests

To run all automated tests:

```bash
flutter test
```

To run a specific test suite:

```bash
# Test SMS parsing and bank strategies
flutter test test/sms_parser_test.dart

# Test transaction categorization logic
flutter test test/transaction_categorizer_test.dart

# Test repository deduplication and storage
flutter test test/transaction_repository_test.dart

# Test UI widgets and modals
flutter test test/widget_test.dart
```

---

## How to Contribute

Contributions are welcome! Follow these steps to contribute:

1. **Fork the Repository**
2. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/support-hdfc-bank
   ```
3. **Add a Bank Parser Strategy**:
   - Implement `BankParserStrategy` in `lib/core/utils/strategies/your_bank_parser_strategy.dart`.
   - Register it in `SmsParser` (`lib/core/utils/sms_parser.dart`).
   - Add corresponding test cases in `test/sms_parser_test.dart`.
4. **Run Tests & Linter**:
   ```bash
   flutter test
   flutter analyze
   ```
5. **Commit your changes**:
   ```bash
   git commit -m "Add HDFC bank SMS parser strategy"
   ```
6. **Push to Branch & Open a Pull Request**:
   ```bash
   git push origin feature/support-hdfc-bank
   ```

Please adhere to the [Contributor Covenant](https://www.contributor-covenant.org/) Code of Conduct.

---

## Credits

- **Flutter & Dart Teams** for the framework and developer tools.
- **Open-source Packages**:
  - [`flutter_sms_inbox`](https://pub.dev/packages/flutter_sms_inbox) - SMS inbox querying
  - [`permission_handler`](https://pub.dev/packages/permission_handler) - Runtime permissions
  - [`shared_preferences`](https://pub.dev/packages/shared_preferences) - Local persistence
  - [`crypto`](https://pub.dev/packages/crypto) - SHA-256 transaction hashing
  - [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) - Iconography

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
