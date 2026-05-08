# 18 — WalkViewModel

> **File:** `lib/features/walk/viewmodels/walk_viewmodel.dart`
> **Category:** feature
> **Added:** 2026-04-30
> **Related files:** `walk_tab.dart`, `day_steps.dart`, `walk_repository.dart`, `main.dart`, `19_screen_walk_tab.md`, `17_model_day_steps.md`, `02_core_entry_point.md`

> ⚠️ **Architecture updated [2026-05-08]:** This ViewModel no longer talks to Firebase directly. All database work (saving steps, loading history, reading goals) has been moved to a new `WalkRepository`. This follows our "Ruthless Extraction" rule to keep ViewModels focused only on state and timing logic.

---

## What is this?

`WalkViewModel` is the brain behind the Walk feature. It does all the heavy lifting so the `WalkTab` screen can stay simple — the screen just reads numbers from this ViewModel and displays them.

Here's what it manages:
- Asking the user for **motion/activity permission** (so the phone lets you read the step sensor)
- Listening to the phone's **hardware pedometer** (the step counter built into every phone)
- Figuring out **how many steps you've taken today** specifically (not since the phone was last turned on)
- Coordinating with the **WalkRepository** to save your progress and load your history
- Remembering your **daily step goal** across app restarts
- Running the **midnight rollover** logic to reset the counter when the day changes

> **What is a ViewModel?** Think of it as a manager sitting between the screen and the data. The screen doesn't talk to the database directly — it asks the ViewModel. The ViewModel asks a **Repository** to do the actual data work, then tells the screen when something changes.

---

## Why does it exist?

Without a ViewModel, all this logic would live inside the `WalkTab` widget. That's messy — widgets are supposed to be about *display*, not *data fetching and hardware interaction*. Keeping the logic here means:
- `WalkTab` stays short and easy to read
- The logic can be tested without building a screen
- If you ever add another screen that needs step data, it can use the same ViewModel

---

## How does it work? (Step by step)

1. **`WalkTab` mounts** and calls `initTracking()` once (via `initState` + `addPostFrameCallback`).
2. **`initTracking()` checks `_trackingStarted` and the current user**. If it's already running, or if nobody is logged in, it returns early.
3. **Loads user-specific preferences** from `SharedPreferences` (last sensor total and last active user). If the user changed, the ViewModel marks the sensor baseline to reset.
4. **Loads the step goal** from the `WalkRepository`. It checks Firestore first, then falls back to local storage if needed.
5. **Loads today's steps from `WalkRepository`** (the source of truth). This makes sure the screen starts from the server value, not a stale local count.
6. **Schedules a midnight rollover** so that at the next day's start, the app automatically refreshes today's step count and rolls it into history.
7. **Attaches a lifecycle observer** so when the app resumes, it refreshes today's steps and the goal.
8. **Requests permission** (Android: `ACTIVITY_RECOGNITION`; iOS: motion sensor access via `NSMotionUsageDescription`). If the user says no, `_hasPermission` stays `false` and the pedometer is never started.
9. **Starts two sensor streams** via the `pedometer` package:
   - `stepCountStream` — fires a new event with the total step count every time you take a step.
   - `pedestrianStatusStream` — fires `"walking"` or `"stopped"` as your activity changes.
10. **Handles step events by delta**. The first sensor value (or a user switch) sets a baseline. After that, the ViewModel adds only the difference between the current sensor total and the last saved sensor total.
11. **Detects day changes** in the step stream. If the date changes mid-session, it asks `WalkRepository` for today's data and resets the local history.
12. **Saves progress** via `WalkRepository` every 30 seconds. Each save also updates the local history list so the UI stays fresh.
13. **`_loadHistory()` asks `WalkRepository`** for all daily step entries, ordered newest-first.
14. **Auth changes reset tracking**. If the signed-in user changes, the ViewModel clears state and cancels streams so the new user starts clean.
15. **`dispose()` cancels** both sensor subscriptions, timers, the midnight rollover timer, and the lifecycle observer when the ViewModel is discarded, preventing memory leaks.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `ChangeNotifier` | A base class that lets a ViewModel say "I changed — anyone watching me, please rebuild" |
| `WalkRepository` | The "courier" class that handles all the actual talking to Firestore |
| `notifyListeners()` | The signal that tells all watching widgets to update |
| `StreamSubscription` | A handle to a live data stream. Like subscribing to a radio station — you call `.cancel()` when you want to stop listening |
| `SharedPreferences` | Local key-value storage on the device. Like sticky notes that survive app restarts but stay on the device |
| `Pedometer` | A Flutter package that wraps the phone's hardware step counter |
| `Permission.activityRecognition` | The `permission_handler` call that asks the user for motion access |
| `Timer.periodic` | A repeating timer — runs a function every N seconds until cancelled |
| `WidgetsBindingObserver` | Lets the ViewModel respond to app lifecycle events like "resumed" |
| `AppLifecycleState.resumed` | The moment the app comes back to the foreground; used to refresh today's data |
| `AppLogger` | A tiny helper that writes debug-only logs with a tag (name) |
| `kIsWeb` | A Flutter constant that is `true` when running in a browser. Step tracking is skipped on web since there's no hardware sensor |
| `dispose()` | A lifecycle method called when the ViewModel is thrown away. Clean up timers and streams here to avoid memory leaks |

---

## Code walkthrough

### The delta logic — "how many steps did I add since last time?"

```dart
Future<void> _onStepCount(StepCount event) async {
  if (_resetLastSensorOnNextEvent || !_hasLastSensorTotal) {
    _resetLastSensorOnNextEvent = false;
    _lastSensorTotal = event.steps;
    _hasLastSensorTotal = true;
    await _persistLastSensorTotal();
    _logStepEvent(event, 0);
    notifyListeners();
    return;
  }

  final delta = event.steps - _lastSensorTotal;
  if (delta < 0) {
    _lastSensorTotal = event.steps;
    await _persistLastSensorTotal();
    _logStepEvent(event, 0);
    notifyListeners();
    return;
  }

  if (delta > 0) {
    _todaySteps += delta;
  }

  _lastSensorTotal = event.steps;
  await _persistLastSensorTotal();
  _logStepEvent(event, delta);
  notifyListeners();
}
```

**What this does:** The pedometer only gives a running total since the phone last rebooted. This code stores the last total and adds only the **delta** on each new event. On first run (or user switch), it saves the current sensor total as the baseline. If the sensor ever goes backward (phone reboot), it resets the baseline again.

---

### delegating data work to the Repository

```dart
Future<void> _saveToFirestore() async {
  if (_auth.currentUser == null) {
    AppLogger.d('WalkFirestore', 'Skip save: no authenticated user');
    return;
  }
  final dateKey = _todayString();
  await _repository.saveTodaySteps(
    dateKey: dateKey,
    steps: _todaySteps,
    goal: _goal.targetSteps,
  );
  _upsertTodayHistory();
}
```

**What this does:** Every 30 seconds, the ViewModel calls this method. Instead of building a complex Firestore query here, it just tells the `WalkRepository` to save the steps. The Repository handles the path names and the actual network call. This keeps the ViewModel focused on the *timing* of the save, not the *details* of the database.

---

### Midnight rollover scheduling

```dart
void _scheduleMidnightRollover() {
  _midnightTimer?.cancel();
  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final delay = nextMidnight.difference(now);
  AppLogger.d(
    'Walk',
    'Midnight rollover scheduled in ${delay.inMinutes}m ${delay.inSeconds % 60}s',
  );
  _midnightTimer = Timer(delay, () {
    AppLogger.d('Walk', 'Midnight rollover timer fired');
    _handleMidnightRollover();
  });
}
```

**What this does:** At the moment you load today's steps (on app startup or app resume), the ViewModel calculates when the next midnight is and sets a timer. When midnight hits, `_handleMidnightRollover()` re-fetches the data from the repository (which will be zero steps for the new day), updates the history list, and reschedules the next midnight timer. This ensures that the step counter resets at midnight automatically.

---

## What to do when you change this file

- [ ] If you change the save interval (currently 30 seconds), update the description in "How does it work?" step 12.
- [ ] If the midnight rollover logic changes, update the "Midnight rollover scheduling" section in the code walkthrough.
- [ ] If you add a new piece of state (e.g. calories, distance), add it to the State section and update the `Key concepts` table.
- [ ] Make sure `_cancelTracking()` cancels the midnight timer if you add or remove any timers.
