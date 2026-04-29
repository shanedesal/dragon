# Project Structure — What Each File and Folder Does

When you open your project, you see a bunch of folders and files. Here's what they all mean.

---

## Top-Level Files

| File | What it does |
|------|-------------|
| `pubspec.yaml` | The app's **shopping list** — lists all external packages (libraries) your app depends on, plus assets like images |
| `analysis_options.yaml` | Rules for code style and warnings — tells the editor what bad habits to flag |
| `firebase.json` | Firebase configuration for the web version of your app |
| `README.md` | A description of the project (shown on GitHub) |

---

## The `lib/` Folder — Where YOUR Code Lives

This is the most important folder. Everything you write goes here.

```
lib/
├── main.dart                        ← The starting point of the entire app
├── firebase_options.dart            ← Auto-generated Firebase config (don't edit manually)
├── features/                        ← Each "feature" of the app lives in its own subfolder
│   ├── auth/                        ← Everything related to login/register/logout
│   │   ├── screens/
│   │   │   ├── splash_screen.dart   ← The intro animation screen
│   │   │   ├── login_screen.dart    ← The login form
│   │   │   └── register_screen.dart ← The registration form
│   │   └── viewmodels/
│   │       └── auth_viewmodel.dart  ← The brain behind login/register/logout logic
│   └── home/                        ← Everything inside the home area after logging in
│       └── screens/
│           ├── home_tab.dart        ← The "Home" tab content (welcome card, dashboard)
│           └── food_tab.dart        ← The "Food" tab content (placeholder for now)
├── shell/                           ← The permanent outer frame shown after login
│   ├── main_shell.dart              ← The app bar, bottom nav bar, and drawer
│   └── navigation_viewmodel.dart   ← Tracks which bottom tab is selected
├── shared/                          ← Reusable pieces used by multiple features
│   └── widgets/
│       ├── error_banner.dart        ← The red error box shown when login fails
│       └── profile_drawer.dart      ← The slide-out side panel (profile + logout)
└── theme/
    └── app_theme.dart               ← All colors and visual style
```

### Why split into folders?

It's like organizing your desk. You COULD put everything in one pile, but it becomes impossible to find anything as the project grows.

The old layout grouped files by *type* — all screens together, all widgets together. The new layout groups files by *feature* — everything about auth lives in `features/auth/`, everything about the home area lives in `features/home/`. This is called **feature-based folder structure** and it's how most real-world Flutter apps are organized.

The `shell/` folder is special — it holds the permanent outer frame of the app (the top bar, the bottom nav bar, the side drawer). It's not a "feature" in itself, but it's the container all features live inside.

The `shared/` folder holds widgets and utilities that are used by *more than one* feature — like the error banner, which is used by both the login and register screens.

---

## The `assets/` Folder

Contains files that are **bundled into the app** — not code, but resources.

```
assets/
└── images/
    ├── logo.svg            ← The small logo used in the app bar
    ├── logo-with-name.svg  ← The larger logo on login/register screens
    └── icon.png            ← The app icon (home screen icon on your phone)
```

SVG = Scalable Vector Graphic. It's like a drawing described in math, so it looks sharp at any size.

---

## Platform Folders (android/, ios/, web/, etc.)

These folders exist because Flutter builds for many platforms. Each one contains platform-specific code and configuration.

| Folder | What it's for |
|--------|--------------|
| `android/` | Android-specific configuration. Contains `google-services.json` for Firebase on Android |
| `ios/` | iPhone-specific configuration. Contains `GoogleService-Info.plist` for Firebase on iOS |
| `web/` | Web-specific config |
| `linux/`, `macos/`, `windows/` | Desktop platform configs |

**You rarely touch these directly.** Flutter handles most of it for you.

---

## The `build/` Folder

Auto-generated when Flutter compiles your code. Never edit this. It's also in `.gitignore` so it won't be pushed to GitHub — it can always be regenerated.

---

## The `.gitignore` File

A list of files/folders that should **NOT** be uploaded to GitHub. Things like:
- Generated build output (huge, regeneratable)
- Secret config files like API keys
- Personal editor settings

This `shanexplain/` folder is **not** in `.gitignore`, so it will be included when you push to GitHub.
