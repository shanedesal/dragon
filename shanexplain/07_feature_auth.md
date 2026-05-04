# 07 — Firebase Authentication

> **File:** N/A — this is a feature, not a single file. The Firebase calls live in `auth_viewmodel.dart`. The ViewModel is used by `login_screen.dart`, `register_screen.dart`, `profile_drawer.dart`, and it is provided in `main.dart`.
> **Category:** feature
> **Added:** 2026-04-29
> **Related files:** `firebase_options.dart`, `12_viewmodel_auth.md`, `04_screen_login.md`, `05_screen_register.md`, `06_screen_home.md`, `14_ui_profile_drawer.md`

---

## What is this?

Firebase Authentication is a service by Google that handles everything related to user accounts — creating them, logging in, logging out, and keeping track of who is currently signed in.

You don't store passwords yourself. Firebase stores them securely in the cloud and gives you simple functions to call.

---

## Why does it exist?

Building your own authentication system from scratch is hard and risky (passwords must be hashed, tokens must be managed, security vulnerabilities must be handled). Firebase Auth does all of that for you in a few lines of code.

---

## How does it work? (Step by step)

### Creating an account (Register)
1. User fills in email + password and taps "Create Account."
2. `RegisterScreen` calls `context.read<AuthViewModel>().register(email, password)`.
3. `AuthViewModel` calls `FirebaseAuth.instance.createUserWithEmailAndPassword(email, password)`.
4. Firebase validates the email format, checks the password is strong enough, and checks no account with that email already exists.
5. If everything is fine, Firebase creates the account and **automatically logs the user in**.
6. `AuthViewModel` claims a **session lock** in Firestore to make sure this account is only active on one device.
7. The auth state changes → your app reacts and navigates to home.

### Logging in
1. User fills in email + password and taps "Sign In."
2. `LoginScreen` calls `context.read<AuthViewModel>().login(email, password)`.
3. `AuthViewModel` calls `FirebaseAuth.instance.signInWithEmailAndPassword(email, password)`.
4. Firebase checks the credentials against its database.
5. If correct, Firebase issues a session token (a secret key stored locally on the device).
6. The ViewModel claims a **session lock** in Firestore. If another device already owns the lock, the user is signed out and shown an error.
7. The auth state changes → your app reacts and navigates to home.

### Staying logged in
- Firebase stores the session token on the device. Next time the app opens, Firebase automatically restores the session — the user doesn't have to log in again.
- `FirebaseAuth.instance.currentUser` returns the user if still logged in, or `null` if not.
- `authStateChanges()` is a live stream that emits an event whenever login state changes (logged in, logged out).
- The app also refreshes the **session lock** every 30 seconds. If the lock is taken by another device, the user is logged out.

### Logging out
1. User opens the `ProfileDrawer` (by tapping the avatar button in the top-left corner) and taps "Logout."
2. `ProfileDrawer` calls `context.read<AuthViewModel>().logout()`.
3. `AuthViewModel` calls `FirebaseAuth.instance.signOut()`.
4. Firebase deletes the local session token.
5. `currentUser` becomes `null`, `authStateChanges()` fires → the router redirects to `/login`.

> **Important:** Screens do not call Firebase directly. All Firebase calls go through `AuthViewModel`. See [12_viewmodel_auth.md](12_viewmodel_auth.md) for how the ViewModel handles loading state, errors, and the actual Firebase calls.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `FirebaseAuth.instance` | The single shared instance of the Firebase Auth service in your app |
| `currentUser` | The currently signed-in user, or `null` if nobody is logged in |
| `authStateChanges()` | A stream — think of it as a notification channel. Fires every time login/logout happens |
| `FirebaseAuthException` | The error type thrown when an auth operation fails. Has a `.code` string you can switch on |
| Session token | A secret key Firebase stores on the device to remember the user is logged in |
| Session lock | A small Firestore document that marks which device is active for this account |
| Heartbeat | A repeating timer that updates the lock so it does not expire |
| `async` / `await` | Auth calls go to the internet, so they take time. `await` pauses until the response arrives |

---

## Error codes reference

These are the Firebase error codes used in this app and what they mean:

| Code | Meaning |
|------|---------|
| `user-not-found` | No account with that email exists |
| `wrong-password` | Email exists but password is wrong |
| `invalid-email` | Email format is invalid |
| `user-disabled` | The account was disabled by an admin |
| `invalid-credential` | Catch-all for bad email/password combo (newer Firebase SDK) |
| `too-many-requests` | Too many failed attempts — Firebase locked the account temporarily |
| `email-already-in-use` | Account with that email already exists (register only) |
| `weak-password` | Password is too short/simple (register only) |
| `operation-not-allowed` | Email/password sign-in is disabled in Firebase Console (register only) |

---

## What to do when you change this file

- [ ] If you add a new sign-in method (Google, Apple, phone), add a new "How does it work" section
- [ ] If you handle new error codes, add them to the Error codes reference table
- [ ] If you add email verification, add a step to the "Creating an account" flow
- [ ] If you add password reset, add a new section for that flow
