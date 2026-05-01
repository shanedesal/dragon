# 18 — WalkViewModel

> **File:** `lib/features/home/viewmodels/walk_viewmodel.dart`
> **Category:** feature
> **Added:** 2026-04-30
> **Related files:** `walk_tab.dart`, `day_steps.dart`, `main.dart`, `19_screen_walk_tab.md`, `17_model_day_steps.md`, `02_core_entry_point.md`

---

## What is this?

`WalkViewModel` is the brain behind the Walk feature. It does all the heavy lifting so the `WalkTab` screen can stay simple — the screen just reads numbers from this ViewModel and displays them.

Here's what it manages:
- Asking the user for **motion/activity permission** (so the phone lets you read the step sensor)
- Listening to the phone's **hardware pedometer** (the step counter built into every phone)
- Figuring out **how many steps you've taken today** specifically (not since the phone was last turned on)
- **Auto-saving** your step count to Firebase every 30 seconds
- **Loading your step history** from Firebase (all your previous days)
- Remembering your **daily step goal** across app restarts

> **What is a ViewModel?** Think of it as a manager sitting between the screen and the data. The screen doesn't talk to Firebase directly — it asks the ViewModel. The ViewModel goes off, does the work, and tells the screen when something changes.

---

## Why does it exist?

Without a ViewModel, all this logic would live inside the `WalkTab` widget. That's messy — widgets are supposed to be about *display*, not *data fetching and hardware interaction*. Keeping the logic here means:
- `WalkTab` stays short and easy to read
- The logic can be tested without building a screen
- If you ever add another screen that needs step data, it can use the same ViewModel

---

## How does it work? (Step by step)

1. **`WalkTab` mounts** and calls `initTracking()` once (via `initState` + `addPostFrameCallback`).
2. **`initTracking()` checks `_trackingStarted`** — if it's already been called (e.g. user left and came back to the tab), it returns immediately. This prevents setting up two pedometer listeners by accident.
3. **Loads saved preferences** from `SharedPreferences` — the step goal, the baseline step count, and the date the baseline was set.
4. **Requests permission** (Android: `ACTIVITY_RECOGNITION`; iOS: motion sensor access via `NSMotionUsageDescription`). If the user says no, `_hasPermission` stays `false` and the pedometer is never started.
5. **Starts two sensor streams** via the `pedometer` package:
   - `stepCountStream` — fires a new event with the total step count every time you take a step.
   - `pedestrianStatusStream` — fires `"walking"` or `"stopped"` as your activity changes.
6. **Handles the "day rollover" problem** in `_onStepCount`: the phone's pedometer counts steps since the last reboot — not since midnight. To get "today's steps," a *baseline* (the sensor reading at midnight or the first step of the day) is saved in `SharedPreferences`. `todaySteps = currentReading − baseline`. If the date has changed since the baseline was saved, the baseline resets to the current reading (starting fresh for the new day).
7. **Guards against negative values** — if the phone reboots mid-day, the sensor resets to 0, making the subtraction go negative. In that case, `todaySteps` is set to the raw reading instead.
8. **Logs step events in debug builds** with `_logStepEvent()` so you can see sensor updates while developing. It is throttled to avoid spam (roughly every 10 seconds or when steps jump by 100+).
9. **A timer fires every 30 seconds** and calls `_saveToFirestore()`, which writes the current step count and goal to `users/{uid}/steps/{YYYY-MM-DD}` in Firestore.
10. **`_loadHistory()` queries Firestore** for all documents in the `steps` sub-collection, ordered newest-first (by document ID — since the IDs are `YYYY-MM-DD` strings, alphabetical descending = newest first). Each document becomes a `DaySteps` object.
11. **`dispose()` cancels** both sensor subscriptions and the timer when the ViewModel is discarded, preventing memory leaks.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `ChangeNotifier` | A base class that lets a ViewModel say "I changed — anyone watching me, please rebuild" |
| `notifyListeners()` | The signal that tells all watching widgets to update |
| `StreamSubscription` | A handle to a live data stream. Like subscribing to a radio station — you call `.cancel()` when you want to stop listening |
| `SharedPreferences` | Local key-value storage on the device. Like sticky notes that survive app restarts but stay on the device |
| `Pedometer` | A Flutter package that wraps the phone's hardware step counter |
| `Permission.activityRecognition` | The `permission_handler` call that asks the user for motion access |
| `Timer.periodic` | A repeating timer — runs a function every N seconds until cancelled |
| `FieldValue.serverTimestamp()` | A special Firestore value that tells Firebase to fill in the server's current time when saving |
| `FieldPath.documentId` | A Firestore way to sort/filter by the document's own ID (the `YYYY-MM-DD` key) |
| `AppLogger` | A tiny helper that writes debug-only logs with a tag (name) |
| `kDebugMode` | A Flutter constant that is `true` only in debug builds; used to silence logs in release |
| `kIsWeb` | A Flutter constant that is `true` when running in a browser. Step tracking is skipped on web since there's no hardware sensor |
| `dispose()` | A lifecycle method called when the ViewModel is thrown away. Clean up timers and streams here to avoid memory leaks |

---

## Code walkthrough

### The baseline logic — "how many steps have I taken TODAY?"

```dart
Future<void> _onStepCount(StepCount event) async {
  final today = _todayString();

  if (_baselineDate != today) {
    AppLogger.d(
      'WalkSteps',
      'Baseline reset: prevDate=$_baselineDate prevBaseline=$_baseline '
          'newDate=$today newBaseline=${event.steps}',
    );
    _baseline = event.steps;
    _baselineDate = today;
    await _prefs?.setInt('step_baseline', _baseline);
    await _prefs?.setString('step_baseline_date', today);
  }

  final computed = event.steps - _baseline;
  _todaySteps = computed < 0 ? event.steps : computed;
  _logStepEvent(event);
  notifyListeners();
}
```

**What this does:** The phone's pedometer counts steps since the last reboot — not since midnight. So if your phone has counted 45,000 steps total since its last restart, but you only walked 3,200 today, this code figures that out. When the date changes (or the first time this runs), it saves the current sensor reading as the *baseline*. Every subsequent reading subtracts the baseline: `3,200 = 48,200 − 45,000`. The `computed < 0` guard handles the edge case where the phone rebooted mid-day and the sensor reset to 0. The extra `_logStepEvent` call writes a throttled debug line so you can see step updates while testing.

---

### The 30-second auto-save

```dart
void _startSaveTimer() {
  AppLogger.d('WalkFirestore', 'Save timer started (30s interval)');
  _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    _saveToFirestore();
  });
}

Future<void> _saveToFirestore() async {
  final user = _auth.currentUser;
  if (user == null) {
    AppLogger.d('WalkFirestore', 'Skip save: no authenticated user');
    return;
  }

  final docId = _todayString();
  AppLogger.d(
    'WalkFirestore',
    'Saving steps=$_todaySteps goal=$_stepGoal '
        'path=users/${user.uid}/steps/$docId',
  );

  try {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('steps')
        .doc(docId)
        .set({
      'steps': _todaySteps,
      'goal': _stepGoal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.d('WalkFirestore', 'Save complete');
  } catch (e, st) {
    AppLogger.d('WalkFirestore', 'Save failed', error: e, stackTrace: st);
    rethrow;
  }
}
```

**What this does:** Every 30 seconds, the timer fires and writes the latest step count to Firestore. The document path is `users/{your-user-id}/steps/2026-04-30` (for example). Using `.set()` means it overwrites whatever was there before — so it's always up to date, not adding duplicate records. The extra `AppLogger` calls are just debug breadcrumbs, and the `try/catch` logs failures if the save throws.

---

### Guard against double-init

```dart
Future<void> initTracking() async {
  if (_trackingStarted) return;
  _trackingStarted = true;
  ...
}
```

**What this does:** The user might navigate away from the Walk tab and come back. `WalkTab.initState()` calls `initTracking()` every time the widget mounts. Without this guard, you'd end up with two pedometer listeners running at the same time, both calling `notifyListeners()` and doubling your step count. The `_trackingStarted` flag ensures the setup only ever runs once.

---

## What to do when you change this file

- [ ] If you change what's saved to Firestore, update the Firestore path description in step 8 of "How does it work?"
- [ ] If you add a new piece of state (e.g. calories, distance), add it to the State section and update the `Key concepts` table.
- [ ] If you change the save interval (currently 30 seconds), update the description in "How does it work?" step 8.
- [ ] If you change the Firestore data structure, the history query in `_loadHistory()` may need updating too — reflect that here.
