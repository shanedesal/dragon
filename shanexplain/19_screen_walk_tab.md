# 19 — Walk Tab Screen

> **File:** `lib/features/home/screens/walk_tab.dart`
> **Category:** screen
> **Added:** 2026-04-30
> **Related files:** `walk_viewmodel.dart`, `day_steps.dart`, `main_shell.dart`, `18_viewmodel_walk.md`, `17_model_day_steps.md`, `13_shell_main.md`

---

## What is this?

The **Walk tab** is the third tab in the app's bottom navigation bar (after Home and Food). It's a step-counting screen that shows:

- A big **circular progress ring** with today's step count in the middle. The ring fills up as you walk and turns green when you hit your goal.
- A **"Walking / Still" badge** that updates live based on your motion.
- A **red permission warning** if you've denied motion access — explaining why steps can't be counted.
- A **daily goal card** showing your target step count, with an edit button to change it.
- A **history section** listing your steps for each previous day, each with a mini progress bar.

The screen gets all its data from `WalkViewModel` — it doesn't talk to Firebase or the sensor directly. Think of `WalkViewModel` as the engine and `WalkTab` as the dashboard.

---

## Why does it exist?

Walking and step tracking is one of the app's core features. This screen makes the data visible and gives the user a way to set their goal and look back at past days.

---

## How does it work? (Step by step)

1. **The shell adds `WalkTab()` as the third tab** — `MainShell._tabs = [HomeTab(), FoodTab(), WalkTab()]`. When the user taps the Walk icon in the bottom nav bar, the shell swaps the body to `WalkTab`.
2. **`WalkTab` is a `StatefulWidget`** — it needs `initState()` to kick off sensor tracking when the tab first appears.
3. **`initState()` logs a debug line and schedules `initTracking()`** via `WidgetsBinding.instance.addPostFrameCallback(...)`. This small trick ensures the widget is fully built before `context.read<WalkViewModel>()` is called (calling it too early would crash).
4. **`WalkViewModel.initTracking()` runs** — requests permission, starts the pedometer, loads history. (See `18_viewmodel_walk.md` for the full detail.)
5. **While initializing**, `WalkTab` shows a loading spinner (`CircularProgressIndicator`) in the centre of the screen. Once `vm.isInitialized` becomes `true`, the real content appears.
6. **The main content is a `CustomScrollView`** with pull-to-refresh support (`RefreshIndicator`). Pulling down logs a debug line and calls `vm.refreshHistory()` to re-fetch from Firestore.
7. **`_StepRingCard` reads `vm.todaySteps` and `vm.stepGoal`** — calculates progress as `todaySteps / stepGoal` (clamped to 0–1 so the ring never overflows). The ring turns green when progress ≥ 1.0. The centre shows the raw number.
8. **`_StatusBadge`** reads `vm.status` — shows a green "Walking" badge or a grey "Still" badge.
9. **`_PermissionBanner`** is only shown if `vm.hasPermission` is `false`. Reminds the user to grant motion permission in device settings.
10. **`_GoalCard`** shows `vm.stepGoal`. The pencil icon opens a dialog (`_showGoalDialog`) with a number text field. The dialog logs open/save/cancel in debug builds, and when saved it calls `vm.setGoal(newValue)`.
11. **`_HistorySection`** maps `vm.history` (a list of `DaySteps`) into `_HistoryItem` widgets. If the list is empty, it shows a friendly "Start walking" empty state.
12. **`_HistoryItem`** shows one row per day: a check/unchecked icon, the formatted date, a mini linear progress bar, the step count, and the goal. The `_formatDate()` helper converts `"2026-04-30"` into `"Today"`, `"Yesterday"`, or `"Apr 30, 2026"`.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `StatefulWidget` | A widget that can hold its own state and has lifecycle methods like `initState()` |
| `initState()` | A method that runs once when the widget first appears on screen — good for kicking off one-time setup |
| `addPostFrameCallback` | "Wait until the first frame is drawn, then run this code." Used here so that `context.read` is safe to call |
| `context.watch<WalkViewModel>()` | Subscribes this widget to the ViewModel — when the ViewModel calls `notifyListeners()`, the widget rebuilds |
| `context.read<WalkViewModel>()` | A one-time read of the ViewModel — used in `initState` and button callbacks where you don't need continuous updates |
| `RefreshIndicator` | The pull-to-refresh wrapper. Swipe down on the list and it calls a function you provide |
| `CustomScrollView` + `SliverList` | A scrollable area built from "slivers" (scroll-aware chunks). Used here to allow pull-to-refresh on the whole screen |
| `CircularProgressIndicator` (double) | Two overlapping progress rings: one full grey ring (the track) and one coloured ring (the progress) |
| `LinearProgressIndicator` | The small horizontal progress bar used in each history row |
| `AlertDialog` | A pop-up dialog box in the middle of the screen |
| `FilteringTextInputFormatter.digitsOnly` | A keyboard formatter that only allows the user to type numbers |
| `clamp(0.0, 1.0)` | Keeps a value between 0 and 1 no matter what — prevents the progress ring from overflowing past full |
| `AppLogger` | A tiny helper that writes debug-only logs when the user interacts with the tab |

---

## Code walkthrough

### The loading gate

```dart
if (!vm.isInitialized) {
  return const Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(CatppuccinMocha.mauve),
    ),
  );
}
```

**What this does:** While the ViewModel is still setting up (asking for permission, loading history), the screen shows a spinner instead of broken/empty UI. Once `isInitialized` becomes `true`, this check is skipped and the real screen is shown. It's a simple "loading gate."

---

### The progress ring

```dart
SizedBox.expand(
  child: CircularProgressIndicator(
    value: 1.0,
    strokeWidth: 14,
    valueColor: const AlwaysStoppedAnimation<Color>(
      CatppuccinMocha.surface1,
    ),
  ),
),
SizedBox.expand(
  child: CircularProgressIndicator(
    value: progress,
    strokeWidth: 14,
    strokeCap: StrokeCap.round,
    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
  ),
),
```

**What this does:** There's no built-in "ring with a track" widget in Flutter. To fake it, two `CircularProgressIndicator` widgets are stacked on top of each other (inside a `Stack`). The first one is always `value: 1.0` (full) and grey — it's the background track. The second one sits on top with `value: progress` and a colour — it's the actual progress arc. Together they look like one ring with a coloured portion.

---

### The goal edit dialog

```dart
AppLogger.d('WalkUI', 'Open goal dialog');
final result = await showDialog<int>(
  context: context,
  builder: (ctx) => AlertDialog(
    ...
    actions: [
      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel')),
      TextButton(
        onPressed: () {
          final val = int.tryParse(controller.text);
          if (val != null && val > 0) Navigator.of(ctx).pop(val);
        },
        child: Text('Save'),
      ),
    ],
  ),
);

if (result != null) {
  AppLogger.d('WalkUI', 'Goal dialog saved: $result');
  await vm.setGoal(result);
} else {
  AppLogger.d('WalkUI', 'Goal dialog canceled');
}
```

**What this does:** `showDialog` is like a function call that returns a value — whatever the dialog "pops" with. If the user taps Save, `Navigator.of(ctx).pop(val)` closes the dialog AND passes the integer back as the return value of `showDialog`. If they tap Cancel, the dialog closes and returns `null`. The code after the `await` checks if `result` is non-null before calling `vm.setGoal()`. The `AppLogger` lines are debug-only breadcrumbs so you can see when the dialog opened and what the user picked.

---

### The date formatter

```dart
String _formatDate(String dateStr) {
  final parts = dateStr.split('-');
  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (d == today) return 'Today';
  if (d == yesterday) return 'Yesterday';

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
```

**What this does:** Converts raw strings like `"2026-04-30"` into human-friendly labels. Today's date becomes `"Today"`, yesterday becomes `"Yesterday"`, and anything older shows the full formatted date like `"Apr 28, 2026"`. The `DateTime` comparison strips the time component (hours, minutes, seconds) by constructing dates with only year/month/day — otherwise two `DateTime` objects representing the same day at different times would not be equal.

---

## What to do when you change this file

- [ ] If you add a new card or section to the screen, document it in "How does it work?" and add any new concepts to the table.
- [ ] If you change the ring colors or goal-reached behavior, update step 7.
- [ ] If you change what the goal dialog accepts (e.g. add a minimum), update the walkthrough for "The goal edit dialog."
- [ ] If the history display changes (e.g. shows distance or calories), update step 11 and 12 and `17_model_day_steps.md`.
