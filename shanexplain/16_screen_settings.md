# 16 — Settings Screen

> **File:** `lib/features/settings/screens/settings_screen.dart`
> **Category:** screen
> **Added:** 2026-04-30
> **Related files:** `lib/shared/widgets/profile_drawer.dart`, `14_ui_profile_drawer.md`

---

## What is this?

The `SettingsScreen` is a full-page screen for app settings. Right now it's an empty placeholder — it has an `AppBar` but no settings options yet. It's reached by tapping "Settings" in the Profile Drawer.

---

## Why does it exist?

Even though this screen has no content yet, having it in place means the "Settings" button in the drawer is no longer a dead end. It's a real screen you can navigate to and back from. As the app grows, things like notification preferences, theme switching, and account management will live here.

---

## How does it work? (Step by step)

1. The user opens the Profile Drawer and taps "Settings."
2. The drawer closes itself with `Navigator.of(context).pop()`.
3. `Navigator.of(context).push(MaterialPageRoute(...))` opens the Settings Screen on top of the home screen.
4. Flutter automatically adds a back button to the `AppBar` because this screen was pushed on top of another one.
5. The user taps the back button → they return to the home screen.

That's it for now — the body of the screen is empty (no `body:` property set yet).

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `Scaffold` | Flutter's standard full-page container |
| `Navigator.push()` | Puts a new screen on top of the current one |
| `MaterialPageRoute` | The standard slide-in animation for opening a new screen |
| `automaticallyImplyLeading` | `AppBar` feature that auto-adds a back button when a screen was pushed on top of something |

---

## Code walkthrough

```dart
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CatppuccinMocha.base,
      appBar: AppBar(
        backgroundColor: CatppuccinMocha.mantle,
        foregroundColor: CatppuccinMocha.text,
        title: const Text('Settings', ...),
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
```
**What this does:** Builds the full screen. The `Scaffold` has a background colour and an `AppBar`, but no `body:` — so the screen is empty below the bar. The `foregroundColor` on the `AppBar` automatically colours the back button that Flutter adds.

---

## What to do when you change this file

- [ ] When you add real settings options, add a "body:" to the `Scaffold` and update the "How does it work" steps
- [ ] If the settings screen gets its own ViewModel, create a new `shanexplain/` file for it
- [ ] If you add a GoRouter route for this screen, update `08_feature_routing.md`
