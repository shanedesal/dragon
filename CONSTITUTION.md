# 🐉 Dragon Fitness App - Project Constitution

This document defines the strict coding standards and architecture rules for our Flutter/Dart fitness application. If you are writing code for this project, you must follow these rules.

## 1. Architecture Rules (MVVM)
We use the **Model-View-ViewModel (MVVM)** pattern integrated with a **Repository** layer.

*   **Screens (Views):** Strictly visual. They listen to ViewModels (e.g., via `ListenableBuilder` or `Provider`) and render UI. **No business logic.**
*   **ViewModels:** Contain all business logic and state management. They talk to Repositories, handle success/error states, and call `notifyListeners()`.
*   **Repositories:** The *only* layer allowed to execute external data fetching (Firebase, local storage, device sensors).
*   **Models:** Pure data structures representing our domain (e.g., `DaySteps`, `UserProfile`).

## 2. Folder & File Conventions
*   **Folders and Files:** Always use `snake_case` (e.g., `auth_viewmodel.dart`).
*   **Classes:** Always use `PascalCase` (e.g., `AuthViewModel`).
*   **Variables/Methods:** Always use `camelCase` (e.g., `fetchSteps()`).
*   **Feature-first grouping:** Code must be organized by feature (`auth`, `home`, `profile`, `settings`), and then by layer (`screens`, `viewmodels`, `models`, `repositories`).
*   **Suffixes:** Append the type to the filename and class name:
    *   Screens: `login_screen.dart` / `LoginScreen`
    *   ViewModels: `walk_viewmodel.dart` / `WalkViewModel`
    *   Repositories: `food_repository.dart` / `FoodRepository`
    *   Tabs/Sub-screens: `walk_tab.dart` / `WalkTab`

## 3. Widget Rules
*   **Default to Stateless:** Always use `StatelessWidget` unless you absolutely need local animation/focus state. Use ViewModels for business state.
*   **Extract ruthlessly:** If a `build` method exceeds 100 lines, extract local widgets into smaller sub-widgets.
*   **No deeply nested trees:** If you find yourself 6 levels deep, abstract part of the tree.

## 4. ViewModel Rules
*   **State Management:** Extend or mixin `ChangeNotifier`.
*   **Private state, public getters:** Keep variables private (`_isLoading`) and expose them via getters (`bool get isLoading => _isLoading;`).
*   **Error Handling:** Always wrap async operations in a `try/catch`. Expose an `errorMessage` property to the UI.
*   **Async flow:** 
    1. Set loading = true
    2. Try: await repository call
    3. Catch: set error message
    4. Finally: set loading = false, `notifyListeners()`

## 5. Model Rules
*   **Immutability:** All properties must be `final`.
*   **Serialization:** Must include `fromJson` and `toJson` (or `toMap`/`fromMap`) to easily transition from Firebase documents to Dart objects.
*   *(Recommended)* Use copyWith methods for state updates rather than direct mutation.

## 6. Shared vs Feature Code (DRY)
*   **Feature-bound:** If a widget or logic piece is only used in one feature (e.g., Auth), it lives inside `lib/features/{feature}/...`.
*   **Shared:** The moment a component or utility is needed by **two or more** features, move it to `lib/shared/widgets/` or `lib/shared/utils/`.

## 7. Firebase & Data Access
*   **NO FIREBASE IN UI OR VMS:** You are strictly forbidden from calling `FirebaseFirestore.instance` or `FirebaseAuth.instance` directly inside a Screen or a ViewModel.
*   **Repository Layer:** All Firebase SDK calls belong in a Repository (e.g., `AuthRepository`, `FirestoreRepository`). The ViewModel calls `await authRepo.login(...)`.

## 8. Logging & Debugging
*   **Use the App Logger:** Always use our custom logger inside `lib/shared/utils/app_logger.dart` for tracking flow or errors.
    ```dart
    AppLogger.info('User logged in successfully');
    AppLogger.error('Failed to fetch steps', e, stackTrace);
    ```

## 9. Strictly Forbidden 🚫
*   **`print()` statements:** Never use `print()`. Use `AppLogger`.
*   **Hardcoded styling:** No hardcoded colors, paddings, or text styles. Use `Theme.of(context)` and globally defined constants (e.g., `AppTheme`).
*   **`BuildContext` inside ViewModels:** ViewModels should *never* know about `BuildContext`. If you need to navigate or show a snackbar, the Screen must observe the ViewModel's state and fire the UI action.
*   **Magic Strings/Numbers:** Extract repetitive strings (Firestore collection names, route names) into constants files.

## 10. Standard File Header
Every new Dart file should start with a brief, standardized header explaining its purpose:

```dart
/// ------------------------------------------------------------------
/// File: [filename.dart]
/// Feature: [Feature Name / Shared / Shell]
/// Description: [1-2 sentences describing what this file does.]
/// ------------------------------------------------------------------
```
