# 08 — Routing (Navigation)

> **File:** `lib/main.dart` — the `_router` and `_AuthNotifier` declarations
> **Category:** feature
> **Added:** 2026-04-29
> **Related files:** `main.dart`, `02_core_entry_point.md`, `07_feature_auth.md`

---

## What is this?

Routing is how the app moves between screens. Instead of manually saying "go to login screen now," you declare a map of paths to screens (like a website URL → page mapping), and let the router handle the rest.

This app uses the **GoRouter** package for routing.

---

## Why does it exist?

Without a router:
- You'd have to manually pass context and call `Navigator.push(...)` everywhere.
- You'd have to manually check "is the user logged in?" before every navigation.
- Keeping login state and screen state in sync is error-prone.

GoRouter centralises all of that. The redirect logic runs automatically whenever you navigate or the auth state changes.

---

## The Routes (The Map)

| Path | Screen shown |
|------|-------------|
| `/splash` | `SplashScreen` |
| `/login` | `LoginScreen` |
| `/register` | `RegisterScreen` |
| `/home` | `MainShell` (the outer shell with bottom nav bar, containing `HomeTab` and `FoodTab`) |

---

## How does it work? (Step by step)

### Normal navigation
1. A widget calls `context.go('/register')` (or any path).
2. GoRouter looks up the path in its routes list.
3. Before showing the screen, it runs the `redirect` function.
4. The redirect either returns `null` (allow) or a different path (override destination).
5. The correct screen is shown.

### Auth-aware redirect
The redirect function is the "traffic cop." Every navigation — and every auth state change — runs through it:

```
Is current path /splash?
  → Yes: allow (return null). The splash screen handles its own exit.

Is the user logged in AND trying to go to /login or /register?
  → Redirect to /home. No point showing login to someone already logged in.

Is the user NOT logged in AND trying to go somewhere other than /login or /register?
  → Redirect to /login. Can't access protected screens without logging in.

Otherwise → allow (return null).
```

### How auth changes trigger the redirect
1. `_AuthNotifier` listens to `FirebaseAuth.instance.authStateChanges()`.
2. When the user logs in or out, Firebase fires an event.
3. `_AuthNotifier` calls `notifyListeners()`.
4. GoRouter is watching `_AuthNotifier` (via `refreshListenable`).
5. GoRouter re-runs the redirect function automatically.
6. Result: the app navigates without any `context.go(...)` call in your screen code.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `GoRouter` | The routing engine from the `go_router` package |
| `context.go('/path')` | Navigates to a path, replacing the current screen |
| `redirect` | A function that runs before every navigation, can override the destination |
| `refreshListenable` | Tells GoRouter to re-run the redirect whenever this object changes |
| `ChangeNotifier` | A class that can notify listeners when something changes (used by `_AuthNotifier`) |
| `initialLocation` | The first path the app opens at |

---

## What to do when you change this file

- [ ] When you add a new screen, add a new `GoRoute` to the routes list and a new row to the Routes table above
- [ ] When a new screen needs auth protection, verify the existing redirect rules cover it (any non-auth route is already protected by rule 3)
- [ ] When you add route parameters (e.g., `/post/:id`), add a new section here explaining it
- [ ] When you add nested routes or shell routes (e.g., a bottom navigation bar), add a section for that
