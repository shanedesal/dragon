# 04 — Login Screen

> **File:** `lib/screens/login_screen.dart`
> **Category:** screen
> **Added:** 2026-04-29
> **Related files:** `auth_viewmodel.dart`, `error_banner.dart`, `05_screen_register.md`, `12_viewmodel_auth.md`, `07_feature_auth.md`

---

## What is this?

The login screen is the form where an existing user types their email and password to sign into the app. It validates the inputs, hands the credentials to `AuthViewModel`, and either lets the router navigate to the home screen or shows an error message.

The screen itself does **not** talk to Firebase directly — all the Firebase logic lives in `AuthViewModel` ([12_viewmodel_auth.md](12_viewmodel_auth.md)). This is the MVVM pattern.

---

## Why does it exist?

Without a login screen, anyone could open the app and immediately access private content. This screen is the "front door" — it checks who you are before letting you in.

---

## How does it work? (Step by step)

1. **User sees the screen** — logo, "Welcome back" heading, email field, password field, Sign In button, and a link to Register.
2. **User fills in their email and password.**
3. **User taps "Sign In"** — the `_submit()` function runs.
4. **Validation runs first** — the form checks:
   - Email is not empty and matches a valid email pattern (has `@` and a `.` domain).
   - Password is not empty.
   - If either fails, a red hint appears under the field and the login is blocked.
5. **If validation passes**, `_submit()` calls `context.read<AuthViewModel>().login(email, password)`. The screen hands the work off to the ViewModel and waits.
6. **The ViewModel calls Firebase** and sets `isLoading = true`. Because the screen is watching the ViewModel (`context.watch`), it automatically redraws — the "Sign In" button becomes a loading spinner.
7. **Firebase responds:**
   - ✅ Success → the ViewModel's `isLoading` goes back to `false`. The router's redirect rule in `main.dart` detects the user is now logged in and navigates to `/home`. No manual navigation needed.
   - ❌ Failure → the ViewModel sets `errorMessage` to a human-readable string. The screen redraws and shows the red error banner.
8. **The "eye" icon** on the password field toggles between showing and hiding the password characters.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `StatefulWidget` | Widget with internal state — here, just the password visibility toggle and form key |
| `GlobalKey<FormState>` | A handle to the Form widget so you can trigger validation from anywhere |
| `TextEditingController` | Lets you read what the user typed in a text field |
| `Form` + `TextFormField` | Flutter's built-in form system with per-field validation |
| `validator` | A function on a field that returns an error string if the input is bad, or `null` if it's fine |
| `obscureText` | Hides the text in a field (shows dots instead of letters) |
| `context.read<AuthViewModel>()` | Gets the ViewModel and calls a method on it (used for one-off actions like button taps) |
| `context.watch<AuthViewModel>()` | Gets the ViewModel AND subscribes to its changes — the screen redraws whenever the ViewModel calls `notifyListeners()` |
| `AuthViewModel` | The class that holds all auth logic and state. Lives in `lib/viewmodels/auth_viewmodel.dart` |
| `dispose()` | Cleanup: called when the screen is removed. Controllers must be disposed here to free memory |

---

## Code walkthrough

```dart
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
```
**What this does:** Creates a "key" that gives us control over the form, and two controllers that hold whatever the user types into the email and password fields. These are the only things the screen owns — no loading flag, no error message.

```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  await context.read<AuthViewModel>().login(
    _emailController.text,
    _passwordController.text,
  );
}
```
**What this does:** First asks the form to validate all fields. If anything is wrong, `validate()` returns `false` and we stop immediately. Otherwise, we hand the email and password straight to the ViewModel. The `.trim()` (removing accidental spaces) now happens inside `AuthViewModel.login()`. Notice there's no `try/catch` here — error handling also lives in the ViewModel.

```dart
final vm = context.watch<AuthViewModel>();
```
**What this does:** This line at the top of `build()` gives us access to the ViewModel AND subscribes to its changes. Whenever `AuthViewModel` calls `notifyListeners()` (which happens when loading starts/stops or an error appears), Flutter calls `build()` again and the screen updates automatically.

```dart
if (vm.errorMessage != null) ...[
  const SizedBox(height: 16),
  ErrorBannerWidget(message: vm.errorMessage!),
],
```
**What this does:** Only shows the red error banner if there IS an error message. The `...[]` syntax is "spread" — it inserts multiple widgets into the list at once.

---

## What to do when you change this file

- [ ] If you add a new field (e.g., "remember me"), document it in step 2 and the key concepts
- [ ] If you change validation rules, update step 4
- [ ] If you add or change error handling, update `12_viewmodel_auth.md` (not this file — errors live in the ViewModel)
