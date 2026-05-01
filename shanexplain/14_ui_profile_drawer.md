# 14 — Profile Drawer

> **File:** `lib/shared/widgets/profile_drawer.dart`
> **Category:** ui
> **Added:** 2026-04-29
> **Related files:** `main_shell.dart`, `12_viewmodel_auth.md`, `06_screen_home.md`, `15_screen_profile.md`, `16_screen_settings.md`

---

## What is this?

The `ProfileDrawer` is a panel that slides in from the left edge of the screen when the user taps the avatar button in the app bar. It shows:

- A tappable profile header: a circular avatar with the user's first email initial, their full email, and a "View your profile →" hint.
- A "Settings" menu item that opens the Settings Screen.
- A red "Logout" button at the bottom.

Think of it like the side menu in Gmail or Spotify — a profile summary plus quick actions.

---

## Why does it exist?

Before this file, the logout button was a small icon crammed into the top-right corner of the app bar. As the app grows, you'll want more profile-related actions (settings, account info, etc.). A drawer gives you room to expand. It's also a cleaner UX pattern than a corner icon for something as significant as logout.

---

## How does it work? (Step by step)

1. `MainShell` registers this widget as its `drawer:` — Flutter handles the sliding animation automatically.
2. When the drawer opens, `ProfileDrawer` reads the current user's email from `AuthViewModel`.
3. It takes the **first character** of the email and converts it to uppercase to use as the avatar initial. If there's no email for some reason, it shows "?".
4. The entire profile header (avatar + email + "View your profile →" hint) is wrapped in an `InkWell`, making it tappable. Tapping it closes the drawer with `Navigator.of(context).pop()`, then immediately opens the `ProfileScreen` using `Navigator.of(context).push()`. This is push/pop navigation — it puts the Profile Screen on top of the home screen, and the back button takes the user back.
5. The Settings list item does the same pattern: close the drawer, then push the `SettingsScreen` on top.
6. The Logout list item closes the drawer and then calls `context.read<AuthViewModel>().logout()`. Firebase signs the user out, the auth state changes, and GoRouter automatically redirects to `/login`.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `Drawer` | Flutter's built-in sliding panel widget |
| `Navigator.of(context).pop()` | Closes the drawer (same as pressing back) |
| `Navigator.of(context).push()` | Opens a new screen on top of the current one — back button returns here |
| `MaterialPageRoute` | The standard slide-in animation used when pushing a new screen |
| `InkWell` | A wrapper that makes any widget tappable and shows a ripple effect when tapped |
| `ListTile` | A Flutter widget for a row with an icon, title, and optional tap handler — standard menu item style |
| `CircleAvatar` | A widget that draws a circle, often used for profile pictures |
| `email[0].toUpperCase()` | Gets the first character of the email string and makes it capital |
| `Spacer()` | Pushes widgets apart inside a Column — puts the logout button at the bottom |
| `context.read<AuthViewModel>().logout()` | Triggers logout via the ViewModel (one-off action, no rebuild needed) |

---

## Code walkthrough

```dart
final email = vm.currentUser?.email ?? '';
final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
```
**What this does:** Gets the logged-in user's email from the ViewModel. Then takes the first letter and capitalizes it for the avatar. The `??` means "if email is null or empty, use '?' as a fallback."

```dart
CircleAvatar(
  radius: 30,
  backgroundColor: Color.fromRGBO(203, 166, 247, 0.2),
  child: Text(initial, ...),
),
```
**What this does:** Draws a soft purple circle with the user's initial letter inside. This is a placeholder avatar — no profile photo upload yet. The `0.2` opacity keeps it subtle against the dark background.

```dart
InkWell(
  borderRadius: BorderRadius.circular(12),
  onTap: () {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  },
  child: Padding( /* avatar + email + hint row */ ),
),
```
**What this does:** Wraps the entire profile header in a tappable area. `InkWell` shows a ripple when tapped. The tap handler does two things in order: closes the drawer first (`pop()`), then pushes the `ProfileScreen` on top of the home screen. The `_` in `builder: (_) => ...` is a shorthand for "I don't need the context argument here."

```dart
ListTile(
  leading: const Icon(Icons.logout_rounded, color: CatppuccinMocha.red),
  title: const Text('Logout', style: TextStyle(color: CatppuccinMocha.red)),
  onTap: () {
    Navigator.of(context).pop();
    context.read<AuthViewModel>().logout();
  },
),
```
**What this does:** The logout button. Tapping it does two things in order: first closes the drawer (so the drawer doesn't linger on screen), then calls `logout()` on the ViewModel. The router then handles the redirect to `/login` automatically.

---

## What to do when you change this file

- [ ] If you add more menu items (e.g., "Help", "About"), add them between the Settings item and the `Spacer()`, and update the "How does it work" steps
- [ ] If you add a real user profile photo, replace the `CircleAvatar` initial approach and update the code walkthrough
- [ ] If the Profile or Settings screens are ever given GoRouter routes, replace the `Navigator.push()` calls with `context.go('/profile')` etc. and update steps 4 and 5
