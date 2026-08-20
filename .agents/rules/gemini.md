---
trigger: always_on
---

# Project Guidelines

## 1. Architecture: BLoC Pattern
*   **Strict BLoC:** Exclusively use the BLoC (Business Logic Component) pattern for state management. 
*   **Separation:** Maintain a strict separation between Presentation (UI), Domain (Business Logic), and Data (Repositories/Providers) layers.

## 2. Data & Persistence
*   **User Rules:** Always use the centralized App Preferences (e.g., `SharedPreferences` or secure storage) to save, read, and manage user-saved rules. 
*   **Single Source of Truth:** Do not bypass the preference repository when accessing user configurations.

## 3. UI & Theming
*   **Component Reusability:** Never duplicate UI code. Build modular, reusable widgets (e.g., custom buttons, input fields, cards) in a dedicated `components` directory.
*   **Global Theme:** Strictly adhere to the provided global color theme. Do not hardcode hex values or colors directly into widgets; always reference the central `ThemeData` or theme extension.

## 4. Server Integration
*   **Dart MCP:** Route all external model context and specific backend interactions through the Dart MCP (Model Context Protocol) server.

## 5. Testing & Quality Assurance
*   **Test Everything:** Always write unit tests for BLoCs/Repositories and widget tests for reusable components. 
*   **Analyze:** Continuously run `dart analyze` before committing. Evaluate performance and edge cases before marking any feature as complete.

## 6. Error & State Discipline
*   **State Coverage:** Every feature BLoC must account for `Loading`, `Loaded`, and `Error` states.
*   **Functional Errors:** Catch exceptions in the data layer and expose them as strongly-typed `Failure` objects.

## 7. Performance & Clean Code
*   **Selective Rebuilds:** Scope `BlocBuilder` to the smallest possible widget subtree.
*   **Const & Immutability:** Enforce `const` constructors on widgets and immutable models via `Equatable`/`Freezed`.
*   **No Hardcoded Text:** Route all user-facing copy through `AppLocalizations`.

## 8. Guardrails & AI Output
*   **No Unapproved Dependencies:** Do not add third-party packages to `pubspec.yaml` without explicit prompt request.
*   **Full Implementation:** Never use truncated placeholder comments (e.g., `// TODO: implement later`) in generated code.