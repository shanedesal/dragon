# 06 — Home (Shell + Tabs)

> ⚠️ **Architecture updated 2026-04-29:** This file was updated to reflect the switch from a single `HomeScreen` to a shell-based layout with a bottom navigation bar, multiple tabs, and a slide-out profile drawer.

> **Files:** `lib/shell/main_shell.dart`, `lib/features/home/screens/home_tab.dart`, `lib/features/home/screens/food_tab.dart`, `lib/features/home/screens/walk_tab.dart`
> **Category:** screen
> **Added:** 2026-04-29
> **Related files:** `navigation_viewmodel.dart`, `auth_viewmodel.dart`, `profile_drawer.dart`, `13_shell_main.md`, `14_ui_profile_drawer.md`, `19_screen_walk_tab.md`

---

## What is this?

After logging in, the user lands on a **shell** — a permanent outer frame that stays on screen the whole time they're in the app. The shell has:

- An **app bar** at the top with the Dragon logo and a profile avatar button on the left.
- A **bottom navigation bar** with two tabs: "Home" and "Food."
- A **slide-out drawer** (a panel that slides in from the left edge) for profile/logout.

The content area in the middle swaps between tabs depending on which one the user tapped. Right now:
- **Home tab** (`HomeTab`) — shows the welcome card with the user's email, a "Dashboard" heading, and a "You're all set!" placeholder.
- **Food tab** (`FoodTab`) — shows a placeholder message. Real content coming later.
- **Walk tab** (`WalkTab`) — a fully working step counter with a circular progress ring, walking/still status badge, daily goal card, and a history list synced to Firestore.

Before this change, there was a single `HomeScreen` with a logout icon crammed into the top-right corner. The shell approach makes it easy to keep adding tabs and features without rewriting everything.

---

## Why does it exist?

Most apps have a persistent frame — the bottom bar, the top bar, the drawer — that never changes between screens. Putting that frame in one place (`MainShell`) means:

- Adding a new tab is just adding one widget to a list.
- The app bar and drawer aren't copy-pasted into every screen.
- Each tab just focuses on its own content — it doesn't need to know about navigation.

---

## How does it work? (Step by step)

1. **The router sends you to `/home`** — which builds `MainShell`.
2. **`MainShell` reads `NavigationViewModel.currentIndex`** — this tells it which tab is currently selected (0 = Home, 1 = Food, 2 = Walk).
3. **The `Scaffold` is built** with three pieces:
   - `appBar:` — Dragon logo + `_ProfileAvatarButton` on the left.
   - `drawer:` — The `ProfileDrawer` widget.
   - `body:` — `_tabs[currentIndex]`, which is `HomeTab()`, `FoodTab()`, or `WalkTab()`.
   - `bottomNavigationBar:` — The `NavigationBar` with three destination buttons.
4. **User taps a bottom tab** → calls `NavigationViewModel.setIndex(i)` → ViewModel updates → `MainShell` rebuilds → `body` shows the new tab.
5. **User taps the avatar button in the app bar** → `Scaffold.of(context).openDrawer()` → the `ProfileDrawer` slides in from the left.
6. **`HomeTab` renders** — it reads the logged-in user's email from `AuthViewModel` and shows the welcome card, dashboard heading, and the `_EmptyState` placeholder widget.
7. **`FoodTab` renders** — just shows a placeholder for now.
8. **`WalkTab` renders** — shows the step ring, goal card, and history. Kicks off sensor tracking on first mount. See `19_screen_walk_tab.md` for the full detail.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `Scaffold` | Flutter's standard screen layout widget. Provides app bar, body, bottom bar, and drawer slots |
| `NavigationBar` | The bar at the bottom of the screen with tab icons |
| `NavigationViewModel` | A ViewModel (state manager) that remembers which tab is selected. Lives in `navigation_viewmodel.dart` |
| `context.watch<NavigationViewModel>()` | Makes `MainShell` listen for tab changes and rebuild when they happen |
| `Drawer` | A panel that slides in from the side of the screen |
| `Scaffold.of(context).openDrawer()` | Opens the drawer programmatically (like pulling it open) |
| `_tabs[currentIndex]` | A list of three widgets — accessing index 0 gives `HomeTab`, index 1 gives `FoodTab`, index 2 gives `WalkTab` |
| Private widget (`_ProfileAvatarButton`) | A small widget defined in the same file as `MainShell`, only usable there (the `_` prefix means private) |

---

## Code walkthrough

```dart
static const List<Widget> _tabs = [HomeTab(), FoodTab(), WalkTab()];

Widget build(BuildContext context) {
  final currentIndex = context.watch<NavigationViewModel>().currentIndex;
  ...
  body: _tabs[currentIndex],
```
**What this does:** `_tabs` is a fixed list of tab widgets. `currentIndex` is whichever tab is selected (0 or 1). Using `_tabs[currentIndex]` as the body is the simplest possible tab switcher — no `TabBarView`, no complex setup. When `NavigationViewModel` changes, `context.watch` causes this widget to rebuild and the new tab appears.

```dart
bottomNavigationBar: NavigationBar(
  selectedIndex: currentIndex,
  onDestinationSelected: (i) =>
      context.read<NavigationViewModel>().setIndex(i),
  destinations: const [
    NavigationDestination(..., label: 'Home'),
    NavigationDestination(..., label: 'Food'),
  ],
),
```
**What this does:** The bottom bar shows two destinations. `selectedIndex` highlights the right one. When the user taps a destination, `setIndex(i)` is called on the ViewModel — the ViewModel updates, which triggers a rebuild, which swaps the tab.

```dart
class _ProfileAvatarButton extends StatelessWidget {
  Widget build(BuildContext context) {
    final email = context.watch<AuthViewModel>().currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    return IconButton(
      onPressed: () => Scaffold.of(context).openDrawer(),
      icon: CircleAvatar(radius: 14, child: Text(initial, ...)),
    );
  }
}
```
**What this does:** Shows a small circle in the app bar with the first letter of the user's email. Tapping it calls `openDrawer()` to slide in the `ProfileDrawer`. It watches `AuthViewModel` so if the user somehow changes, the initial letter updates.

---

## What to do when you change this file

- [ ] When you add a new tab, add a new widget to `_tabs` and a new `NavigationDestination` to the `bottomNavigationBar`
- [ ] If you replace the placeholder icons with SVGs, update the code walkthrough
- [ ] When `HomeTab` gets real content, update step 6 in "How does it work?"
- [ ] When `FoodTab` gets real content, update step 7 and consider creating a dedicated shanexplain doc for it
- [ ] When `WalkTab` gains new features, update step 8 and `19_screen_walk_tab.md`
