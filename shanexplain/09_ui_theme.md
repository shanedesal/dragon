# 09 — Theme (Colors and Visual Style)

> **File:** `lib/theme/app_theme.dart`
> **Category:** ui
> **Added:** 2026-04-29
> **Related files:** Every screen and widget file imports from this

---

## What is this?

`app_theme.dart` defines the **visual identity** of the entire app in one place — all the colors, text styles, button styles, and input field styles. Instead of writing `Color(0xFF1e1e2e)` everywhere, you write `CatppuccinMocha.base` and it means the same thing.

The color palette used is called **Catppuccin Mocha** — a popular dark theme with warm, pastel-like colors.

---

## Why does it exist?

Without a theme:
- You'd copy-paste the same colors everywhere.
- Changing the app's look would require editing every single file.
- There'd be no consistency.

With a theme, you change one file and the whole app updates.

---

## How does it work? (Step by step)

1. **`CatppuccinMocha`** is a class full of `static const Color` values — named color constants. Nothing runs, they're just named hex codes.
2. **`AppTheme.darkTheme`** is a `ThemeData` object — Flutter's way of describing the complete visual style of an app.
3. `darkTheme` is passed to `MaterialApp.router(theme: ...)` in `main.dart`, applying it globally.
4. Any widget that calls `Theme.of(context).textTheme.bodyMedium` or `Theme.of(context).colorScheme.primary` gets the values defined here automatically.

---

## Color Palette Reference

The Catppuccin Mocha palette is split into groups:

| Group | Colors | Used for |
|-------|--------|---------|
| Accents | `mauve`, `blue`, `green`, `red`, `peach`, etc. | Buttons, highlights, icons, badges |
| Text | `text`, `subtext1`, `subtext0` | Body copy, secondary text, hints |
| Overlays | `overlay2`, `overlay1`, `overlay0` | Borders, disabled states, icon colors |
| Surfaces | `surface2`, `surface1`, `surface0` | Cards, input fields, elevated containers |
| Backgrounds | `base`, `mantle`, `crust` | Screen backgrounds (darkest colors) |

**Quick cheat sheet:**
- `base` (`#1e1e2e`) — the main dark background color of every screen
- `surface0` (`#313244`) — slightly lighter, used for cards and text field backgrounds
- `mauve` (`#cba6f7`) — the primary purple accent (buttons, focused borders)
- `text` (`#cdd6f4`) — the main light text color
- `red` (`#f38ba8`) — used for errors

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `ThemeData` | Flutter's object that holds the complete visual config of an app |
| `ColorScheme` | A structured set of named roles (primary, surface, error, etc.) mapped to actual colors |
| `TextTheme` | A structured set of named text styles (headlineLarge, bodyMedium, etc.) |
| `static const` | A value that belongs to the class itself (not an instance) and never changes |
| `Theme.of(context)` | Looks up the nearest theme in the widget tree — used in screens to access theme colors |

---

## Code walkthrough

```dart
colorScheme: const ColorScheme.dark(
  primary: CatppuccinMocha.mauve,
  error: CatppuccinMocha.red,
  surface: CatppuccinMocha.base,
  ...
),
```
**What this does:** Maps semantic color roles to actual palette colors. "Primary" means "the main action color" — Flutter uses it for buttons, focused borders, etc. By setting it here, every `ElevatedButton` in the app uses `mauve` without you having to specify it per button.

```dart
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: CatppuccinMocha.surface0,
  ...
),
```
**What this does:** Defines the default look for every `TextFormField` in the app — background color, border style, icon colors, etc. This is why all your text fields look consistent without repeating style code.

---

## What to do when you change this file

- [ ] If you add new color constants to `CatppuccinMocha`, add them to the palette reference table
- [ ] If you switch from Catppuccin to another palette, rewrite the "Color Palette Reference" section
- [ ] If you add a light theme, add a new section explaining `AppTheme.lightTheme`
- [ ] If you add custom component themes (e.g., `CardTheme`, `BottomNavigationBarTheme`), document each one
