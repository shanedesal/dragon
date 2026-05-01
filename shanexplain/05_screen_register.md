# 05 — Register Screen

> **File:** `lib/screens/register_screen.dart`
> **Category:** screen
> **Added:** 2026-04-29
> **Related files:** `auth_viewmodel.dart`, `error_banner.dart`, `04_screen_login.md`, `12_viewmodel_auth.md`, `07_feature_auth.md`

---

## What is this?

The register screen is where a brand-new user creates an account. They enter their email, choose a password, and confirm it. If everything checks out, the screen hands the details to `AuthViewModel`, which creates the Firebase account and the user is automatically sent to the home screen.

The screen itself does **not** talk to Firebase directly — all the Firebase logic lives in `AuthViewModel` ([12_viewmodel_auth.md](12_viewmodel_auth.md)). This is the MVVM pattern.

It works almost identically to the login screen, with one extra field: "Confirm Password."

---

## Why does it exist?

New users have no account yet, so they can't log in. This screen is the "sign-up desk" — it collects their details and creates a new Firebase account for them.

---

## How does it work? (Step by step)

1. **User sees the screen** — logo, "Create account" heading, email field, password field, confirm-password field, "Create Account" button, and a "Sign in" link at the bottom.
2. **User fills in all three fields.**
3. **User taps "Create Account"** — the `_submit()` function runs.
4. **Validation runs first:**
   - Email: not empty, valid email format.
   - Password: not empty, at least 6 characters.
   - Confirm Password: not empty, must exactly match the password field.
   - Any failure shows a red hint under that field and blocks the request.
5. **If validation passes**, `_submit()` calls `context.read<AuthViewModel>().register(email, password)`. The screen hands the work to the ViewModel.
6. **The ViewModel calls Firebase** and sets `isLoading = true`. The screen watches the ViewModel and automatically redraws — the button becomes a loading spinner.
7. **Firebase responds:**
   - ✅ Success → the new account is created. The router detects the user is now logged in and automatically navigates to `/home`.
   - ❌ Failure → the ViewModel sets `errorMessage` (e.g., for `email-already-in-use`) and the screen redraws showing the red error banner.
8. **"Already have an account? Sign in"** — tapping this navigates to `/login`.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `createUserWithEmailAndPassword` | Firebase function that creates a brand-new user account (called inside `AuthViewModel`, not here) |
| Cross-field validation | Checking that confirm-password matches password — done inside the confirm field's `validator` |
| `TextEditingController` | Holds what the user typed; we access `.text` to read the value |
| `context.read<AuthViewModel>()` | Gets the ViewModel and calls a method on it (used for one-off actions like button taps) |
| `context.watch<AuthViewModel>()` | Subscribes to ViewModel changes — screen redraws whenever `notifyListeners()` fires |

---

## Code walkthrough

```dart
validator: (v) {
  if (v == null || v.isEmpty) return 'Please confirm your password';
  if (v != _passwordController.text) return 'Passwords do not match';
  return null;
},
```
**What this does:** This is the validator for the "Confirm Password" field. It reads the current value of the password field (`_passwordController.text`) and compares it to what was typed in the confirm field. If they don't match, a red hint appears. Returning `null` means "all good."

```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  await context.read<AuthViewModel>().register(
    _emailController.text,
    _passwordController.text,
  );
}
```
**What this does:** Validates first. If the form is fine, it hands the email and password straight to the ViewModel. No Firebase code here, no try/catch here — all of that lives in `AuthViewModel.register()`. The screen just delegates and waits.

---

## What to do when you change this file

- [ ] If you add more fields (e.g., display name, phone number), add them to steps 2 and 4
- [ ] If you change validation rules, update step 4
- [ ] If you add email verification after registration, add a new step 8 explaining that flow
- [ ] If you add or change error handling, update `12_viewmodel_auth.md` (not this file — errors live in the ViewModel)
