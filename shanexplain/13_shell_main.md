# 13 — Shell & Bottom Navigation

> **Files:** `lib/shell/main_shell.dart`, `lib/shell/navigation_viewmodel.dart`
> **Category:** feature
> **Added:** 2026-04-29
> **Related files:** `06_screen_home.md`, `14_ui_profile_drawer.md`, `02_core_entry_point.md`, `12_viewmodel_auth.md`, `19_screen_walk_tab.md`, `21_screen_food_tab.md`

---

## What is this?

After login, the user enters a **shell** — a permanent outer frame that stays on screen no matter which tab they're on. The shell provides:

- An **app bar** at the top (Dragon logo + avatar button on the left).
- A **bottom navigation bar** for switching between three tabs (Home, Food, Walk).
- A **drawer slot** for the `ProfileDrawer` to slide in from the left.

The shell is made of two files:
- `main_shell.dart` — the visual widget. Draws the frame, shows the right tab, wires up the navigation.
- `navigation_viewmodel.dart` — the memory. Remembers which tab is selected. Tells `MainShell` when to switch.

---

## Why does it exist?

The old approach had one big `HomeScreen` that tried to do everything. As you add features, you'd end up with a single massive file.

The shell pattern separates **"the outer container"** from **"the content inside each tab."** The shell stays the same; only the content slot changes. It's like a TV — the TV itself (shell) stays in place, you just switch channels (tabs).

---

## How does it work? (Step by step)

### Switching tabs
1. The user taps a destination in the bottom navigation bar.
2. `onDestinationSelected` fires with the index (0 for Home, 1 for Food, 2 for Walk).
3. `context.read<NavigationViewModel>().setIndex(i)` is called.
4. Inside `NavigationViewModel.setIndex()`, the index is updated and `notifyListeners()` is called — but *only* if the index actually changed (no unnecessary rebuilds).
5. `MainShell` is watching `NavigationViewModel` with `context.watch`, so it rebuilds.
6. `body: _tabs[currentIndex]` now shows the new tab widget.

### Opening the drawer
1. The user taps the avatar button (`_ProfileAvatarButton`) in the top-left of the app bar.
2. `Scaffold.of(context).openDrawer()` is called.
3. The `ProfileDrawer` slides in from the left.

### How `NavigationViewModel` works
It's a very small ViewModel — just one number with a setter:

```dart
class NavigationViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
```

The `if (_currentIndex != index)` check is a small optimization: if you tap the tab you're already on, nothing happens. This avoids an unnecessary screen rebuild.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| Shell / frame | An outer widget that stays constant while inner content changes |
| `NavigationBar` | Flutter's built-in bottom tab bar widget |
| `NavigationDestination` | One item (icon + label) in a `NavigationBar` |
| `_tabs[currentIndex]` | Picks a widget from a list using a number as the key |
| `NavigationViewModel` | A ChangeNotifier that holds the currently selected tab index |
| `context.watch<T>()` | Subscribe to a ViewModel — rebuild when it changes |
| `context.read<T>()` | Access a ViewModel for a one-off action — no subscription |
| `Scaffold.of(context).openDrawer()` | Tells the nearest `Scaffold` to open its drawer |

---

## Code walkthrough

```dart
static const List<Widget> _tabs = [HomeTab(), FoodTab(), WalkTab()];

Widget build(BuildContext context) {
  final currentIndex = context.watch<NavigationViewModel>().currentIndex;
  return Scaffold(
    ...
    body: _tabs[currentIndex],
    bottomNavigationBar: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) =>
          context.read<NavigationViewModel>().setIndex(i),
      ...
    ),
  );
}
```
**What this does:** `_tabs` is a fixed list of tab widgets. `context.watch` subscribes `MainShell` to `NavigationViewModel`, so whenever the index changes, the whole shell rebuilds and `_tabs[currentIndex]` shows the correct tab. The `NavigationBar`'s `selectedIndex` keeps the bottom highlight in sync, and `onDestinationSelected` wires taps back to the ViewModel.

```dart
class _ProfileAvatarButton extends StatelessWidget {
  Widget build(BuildContext context) {
    final email = context.watch<AuthViewModel>().currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    return IconButton(
      onPressed: () => Scaffold.of(context).openDrawer(),
      icon: CircleAvatar(
        radius: 14,
        backgroundColor: CatppuccinMocha.mauve.withValues(alpha: 0.2),
        child: Text(initial),
      ),
    );
  }
}
```
**What this does:** A private widget (the `_` makes it only usable inside `main_shell.dart`) that renders the user's first email initial in a small circle. Tapping it opens the drawer. The `_` prefix is a signal: "this is an implementation detail, not a public widget."

---

## What to do when you change this file

- [ ] When you add a new tab, add a new widget to `_tabs`, a new `NavigationDestination`, and optionally a new `shanexplain/` doc for the tab's content
- [ ] If you add route parameters or nested navigation inside a tab, read up on `ShellRoute` in GoRouter (a more advanced version of this pattern)
- [ ] If `NavigationViewModel` grows (e.g., page titles, tab history), update the "How it works" section and key concepts
