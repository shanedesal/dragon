# 15 — Profile Screen

> **File:** `lib/features/profile/screens/profile_screen.dart`
> **Category:** screen
> **Added:** 2026-04-30
> **Related files:** `lib/shared/widgets/profile_drawer.dart`, `lib/features/auth/viewmodels/auth_viewmodel.dart`, `14_ui_profile_drawer.md`

---

## What is this?

The `ProfileScreen` is a full-page screen that shows the logged-in user's profile information. Right now it displays a large version of their avatar initial and their email address. It's reached by tapping on the profile header inside the Profile Drawer.

---

## Why does it exist?

The drawer is a compact side panel — there's only so much you can fit in it. As the app grows, you'll want to let users edit their name, upload a photo, see account stats, and more. The Profile Screen is the dedicated space for all of that. For now it's a placeholder, but it's already connected and navigable.

---

## How does it work? (Step by step)

1. The user opens the Profile Drawer and taps on the avatar/email area at the top.
2. The drawer closes itself with `Navigator.of(context).pop()`.
3. Immediately after, `Navigator.of(context).push(MaterialPageRoute(...))` opens the Profile Screen on top of the home screen.
4. The Profile Screen builds a `Scaffold` (the standard Flutter full-page container) with an `AppBar` at the top.
5. Because this screen was *pushed* onto the navigation stack, Flutter automatically adds a back button to the `AppBar` — no code needed for that.
6. The screen reads the logged-in user's email from `AuthViewModel` using `context.watch<AuthViewModel>()`.
7. It takes the first character of the email, capitalises it, and shows it inside a large `CircleAvatar`.
8. Below the avatar it shows the full email address.
9. The user taps the back button → Flutter removes this screen from the stack → they're back on the home screen.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `Scaffold` | Flutter's standard full-page container — provides the `AppBar`, body area, and more |
| `Navigator.push()` | Adds a new screen on top of the current one (like placing a new plate on a pile) |
| `Navigator.pop()` | Removes the top screen from the pile, going back to whatever was underneath |
| `MaterialPageRoute` | The standard slide-in animation for navigating to a new screen |
| `automaticallyImplyLeading` | An `AppBar` setting that defaults to `true` — when `true`, Flutter adds a back button automatically if there's a screen underneath |
| `context.watch<AuthViewModel>()` | Reads data from the ViewModel and rebuilds this widget if that data changes |

---

## Code walkthrough

```dart
final email = context.watch<AuthViewModel>().currentUser?.email ?? '';
final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
```
**What this does:** Grabs the logged-in user's email from the ViewModel. If there's no email for any reason, it falls back to an empty string, and then `initial` falls back to `'?'`. The `?` means "this might be null — if it is, use the fallback on the right instead."

```dart
appBar: AppBar(
  backgroundColor: CatppuccinMocha.mantle,
  foregroundColor: CatppuccinMocha.text,
  title: const Text('Profile', ...),
  centerTitle: true,
  elevation: 0,
),
```
**What this does:** Sets up the top bar with the title "Profile". The `foregroundColor` colours everything inside the bar — including the back button arrow that Flutter adds automatically. `elevation: 0` removes the shadow line below the bar.

```dart
CircleAvatar(
  radius: 52,
  backgroundColor: Color.fromRGBO(203, 166, 247, 0.15),
  child: Text(
    initial,
    style: const TextStyle(
      color: CatppuccinMocha.mauve,
      fontSize: 44,
      fontWeight: FontWeight.w700,
    ),
  ),
),
```
**What this does:** Draws a large soft-purple circle with the user's initial inside. `radius: 52` makes it noticeably bigger than the drawer's avatar (`radius: 30`). This is still a placeholder — no photo upload yet.

---

## What to do when you change this file

- [ ] When you add profile editing (name, photo), add new sections to "How does it work" and the code walkthrough
- [ ] If you add a route for this screen in GoRouter, update `08_feature_routing.md` with the new path
- [ ] If the screen starts using its own ViewModel, add a new `shanexplain/` file for it and link it in the header
