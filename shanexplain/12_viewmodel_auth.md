# 12 — AuthViewModel (MVVM Pattern)

> **File:** `lib/features/auth/viewmodels/auth_viewmodel.dart`
> **Category:** feature
> **Added:** 2026-04-29
> **Related files:** `04_screen_login.md`, `05_screen_register.md`, `06_screen_home.md`, `02_core_entry_point.md`, `07_feature_auth.md`, `14_ui_profile_drawer.md`

---

## What is this?

`AuthViewModel` is the **brain** of all authentication in the app. It holds the logic for logging in, registering, and logging out. It also tracks whether a network call is in progress and whether an error occurred.

The screens (`LoginScreen`, `RegisterScreen`, `HomeScreen`) no longer talk to Firebase directly. They ask the ViewModel to do it instead.

---

## Why does it exist?

Before this file was created, each screen had its own Firebase code, loading state, and error-handling logic. That meant:

- `_mapFirebaseError()` was copy-pasted in both `login_screen.dart` and `register_screen.dart`
- If Firebase added a new error code, you'd have to update two files
- Testing or debugging the login logic meant digging through screen code mixed with UI code

The ViewModel separates **"what to do"** (ViewModel) from **"how to show it"** (screen). This is the **MVVM pattern** — Model-View-ViewModel. It's the same pattern you'd use with a `ViewModel` class in Kotlin/Android.

---

## How does it fit into the app? (The MVVM idea)

Think of it like a restaurant:

- **The kitchen (ViewModel)** — does the actual cooking (Firebase calls, error handling, state tracking)
- **The waiter (Screen)** — takes the order from the customer and brings the food back. Doesn't cook anything.
- **The customer (User)** — just sees the food (rendered UI)

The waiter doesn't need to know how the food is made. The screen doesn't need to know how Firebase works.

---

## How does it work? (Step by step)

### When the user taps "Sign In":
1. The screen calls `context.read<AuthViewModel>().login(email, password)`.
2. `login()` sets `_isLoading = true` and calls `notifyListeners()` — which tells every screen watching this ViewModel to redraw. The button becomes a spinner.
3. Firebase is called: `signInWithEmailAndPassword(email, password)`.
4. **Success** → Firebase logs the user in. `_isLoading` is set back to `false`. GoRouter's redirect detects the login and navigates to `/home` automatically.
5. **Failure** → The `FirebaseAuthException` is caught. `_errorMessage` is set to a human-readable string. `notifyListeners()` fires again. The screen redraws and shows the error banner.

### When the user taps "Sign Out":
1. The screen calls `context.read<AuthViewModel>().logout()`.
2. `logout()` calls `FirebaseAuth.instance.signOut()`.
3. The auth state changes → GoRouter redirects to `/login`.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `ChangeNotifier` | A Flutter base class that lets you "announce" changes to anything listening. Like a loudspeaker. |
| `notifyListeners()` | The loudspeaker button — calling this tells all screens watching this ViewModel to redraw. |
| `context.watch<AuthViewModel>()` | Used in a screen's `build()` method. "I want to redraw every time this ViewModel changes." |
| `context.read<AuthViewModel>()` | Used when calling a method (like from a button tap). "Just give me the ViewModel, I'm not subscribing to changes." |
| `ChangeNotifierProvider` | Set up in `main.dart`. Makes the ViewModel available to every screen in the app. Like a shared bulletin board. |
| Private fields (`_isLoading`) | The `_` prefix means only this class can change the value. Screens can only *read* it through the getter. |
| Getter (`get isLoading`) | A read-only window into a private field. Screens see `vm.isLoading` but can't set it directly. |

---

## Code walkthrough

```dart
class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => FirebaseAuth.instance.currentUser;
```
**What this does:** Declares the state this ViewModel owns. `_isLoading` and `_errorMessage` are private — the `_` prefix means only code inside this class can write to them. The `get` lines are "getters" — read-only windows that screens can peek through.

```dart
Future<void> login(String email, String password) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    _errorMessage = _mapFirebaseError(e.code);
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```
**What this does:** The login method. It first sets loading to `true` and clears any old error, then announces the change so the button becomes a spinner. Then it tries the Firebase call. If it fails, it stores a friendly error message. Either way, `finally` runs at the end — it turns loading off and announces again so the screen redraws.

```dart
String _mapFirebaseError(String code) {
  switch (code) {
    case 'user-not-found': return 'No account found with this email.';
    case 'wrong-password': return 'Incorrect password. Please try again.';
    case 'email-already-in-use': return 'An account already exists with this email.';
    // ...
    default: return 'Something went wrong. Please try again.';
  }
}
```
**What this does:** Translates Firebase's robot-speak error codes into messages a real user can understand. Previously this existed in BOTH the login and register screen files (copy-pasted). Now it lives once, here.

---

## Comparison: Before vs After MVVM

| Before (logic in screen) | After (logic in ViewModel) |
|---|---|
| `_login()` method inside `login_screen.dart` | `login()` method inside `auth_viewmodel.dart` |
| `setState(() => _isLoading = true)` | `_isLoading = true; notifyListeners()` |
| `setState(() => _errorMessage = ...)` | `_errorMessage = ...; notifyListeners()` |
| `_mapFirebaseError()` copy-pasted in 2 files | `_mapFirebaseError()` in 1 file |
| Screen directly imports `firebase_auth` | Screen imports only `auth_viewmodel.dart` |

---

## Kotlin/Android comparison

If you've done Android with Kotlin, this maps directly to what you already know:

| Kotlin/Android | Flutter (this project) |
|---|---|
| `ViewModel : ViewModel()` | `AuthViewModel extends ChangeNotifier` |
| `StateFlow` / `LiveData` | Private fields + `notifyListeners()` |
| `viewModel.stateFlow.collect {}` | `context.watch<AuthViewModel>()` in `build()` |
| `viewModel.doSomething()` | `context.read<AuthViewModel>().method()` |
| `ViewModelProvider` / Hilt `@HiltViewModel` | `ChangeNotifierProvider(create: (_) => AuthViewModel())` in `main.dart` |

---

## What to do when you change this file

- [ ] If you add a new auth method (e.g., Google Sign-In), add a new public method and document it here
- [ ] If you add new Firebase error codes to `_mapFirebaseError`, update the table in `07_feature_auth.md` too
- [ ] If you add more shared state (e.g., `displayName`, `photoUrl`), add new getters and document them
