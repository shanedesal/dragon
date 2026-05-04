# 11 — Full App Flow (Start to Finish)

> **File:** N/A — this is a concept document tracing the entire user journey
> **Category:** core
> **Added:** 2026-04-29
> **Related files:** All screen and feature files

---

## The Complete Journey

This document traces what happens from the moment a user taps the app icon to the moment they're looking at the home screen. It ties together everything from the other explanation files.

---

## First Ever Launch (Brand New User)

```
1. User taps the app icon on their phone

2. The OS launches the Flutter engine
   └─ Flutter calls main() in main.dart

3. main() runs:
   a. WidgetsFlutterBinding.ensureInitialized()
      → Flutter's internal engine is prepared
   b. Firebase.initializeApp()
      → App connects to your Firebase project in the cloud
   c. runApp(MyApp())
      → The widget tree starts building

4. MyApp builds MaterialApp.router
   └─ The router starts at initialLocation: '/splash'

5. Redirect check runs:
   - Current path: /splash → rule says "do nothing" → allowed

6. SplashScreen is shown
   └─ Logo animates in (fade + scale)
   └─ App name slides up
   └─ After 2.8 seconds: context.go('/login')

7. Redirect check runs again:
   - Current path: /login
   - Is user logged in? NO (first launch, no account)
   - Is /login an auth route? YES → allowed

8. LoginScreen is shown

9. User taps "Don't have an account? Register"
   └─ context.go('/register')

10. Redirect check:
    - /register, not logged in, it's an auth route → allowed

11. RegisterScreen is shown

12. User fills in email, password, confirm password → taps "Create Account"

13. Validation passes:
    - Email format ✓
    - Password ≥ 6 chars ✓
    - Confirm matches password ✓

14. _register() calls:
    FirebaseAuth.instance.createUserWithEmailAndPassword(email, password)
    └─ Loading spinner shows

15. Firebase creates the account + logs the user in
   └─ authStateChanges() fires an event

16. AuthViewModel tries to claim the session lock in Firestore
   └─ If another device owns the lock, the user is signed out and shown an error

17. _AuthNotifier.notifyListeners() is called
   └─ GoRouter re-runs its redirect function

18. Redirect check:
   - Current path: /register
   - Is user logged in? YES (just created account)
   - Is /register an auth route? YES
   - Rule: "logged in + on auth route → redirect to /home"

19. App navigates to /home

20. MainShell is shown:
    └─ Bottom navigation bar appears with "Home", "Food", and "Walk" tabs
    └─ HomeTab is the active tab
    └─ User's email displayed in the welcome card
    └─ Dashboard placeholder visible
```

---

## Returning User (Already Has Account)

```
1. User taps app icon

2-4. Same as above (Flutter boots, Firebase connects, MyApp builds)

5. SplashScreen is shown for 2.8 seconds

6. After delay: context.go('/login')

7. Redirect check:
   - /login, not logged in yet (Firebase is still checking)
   - It's an auth route → allowed

8. LoginScreen is shown (very briefly, or possibly skipped if Firebase is fast)

   --- Meanwhile, Firebase restores the saved session from device storage ---

9. authStateChanges() fires because Firebase found the saved session
   └─ _AuthNotifier.notifyListeners()
   └─ GoRouter re-runs redirect

10. AuthViewModel tries to claim the session lock in Firestore
   └─ If another device owns the lock, the user is signed out and stays on /login

11. Redirect check:
   - Current path: /login
   - Is user logged in? YES (session restored)
   - On auth route? YES → redirect to /home

12. App navigates to /home automatically (user never had to type anything)
   └─ MainShell is shown with the HomeTab active
```

> **Note:** In practice, Firebase session restoration is very fast, so the user may see the login screen flash for a split second or not at all, depending on device speed.

---

## Logging Out

```
1. User taps the avatar button in the top-left corner of the app bar
   └─ The ProfileDrawer slides in from the left

2. User taps "Logout" at the bottom of the drawer

3. AuthViewModel releases the session lock and stops the heartbeat

4. FirebaseAuth.instance.signOut() is called via AuthViewModel

5. Firebase deletes the session token from the device
   └─ authStateChanges() fires

6. _AuthNotifier.notifyListeners()
   └─ GoRouter re-runs redirect

7. Redirect check:
   - Current path: /home
   - Is user logged in? NO
   - Is /home an auth route? NO
   - Rule: "not logged in + not on auth route → redirect to /login"

8. App navigates to /login
```

---

## Summary: Why No Manual Navigation Calls?

You'll notice the screen code never has `context.go('/home')` after a successful login. That's intentional. The flow is:

```
Auth state changes (Firebase)
  → _AuthNotifier fires
    → GoRouter re-evaluates redirect
      → Router navigates automatically
```

This is a "reactive" approach — screens don't tell the app where to go; they just change auth state, and the router figures out the rest. It's more robust because the redirect rules are declared in one place (`main.dart`) and enforced globally.

---

## What to do when you change this file

- [ ] If you add a new step in any flow (e.g., email verification after register), insert it into the numbered list above
- [ ] If you add a new auth method (Google sign-in), add a new top-level flow section
- [ ] If you add onboarding screens between register and home, document that as a new flow
