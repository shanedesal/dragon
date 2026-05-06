# 22 - FoodViewModel

> **File:** `lib/features/food/viewmodels/food_viewmodel.dart`
> **Category:** feature
> **Added:** 2026-05-04
> **Related files:** `food_tab.dart`, `food_repository.dart`, `food_entry.dart`, `daily_goals.dart`, `24_feature_food.md`, `21_screen_food_tab.md`, `23_model_food_data.md`, `02_core_entry_point.md`

> ⚠️ **Updated [2026-05-06]:** FoodViewModel now watches the app lifecycle and auto-refreshes food data when the app resumes. It also schedules a refresh at midnight to clear stale data. This keeps the UI accurate across day changes and app background/foreground transitions.

---

## What is this?

`FoodViewModel` is the brain behind the Food tab. It stores the current daily goals, the list of food entries for today, macro totals (protein, carbs, fat), and the loading or error state.

The Food tab reads values from this ViewModel and never talks to Firestore directly.

---

## Why does it exist?

Without a ViewModel, the Food tab would have to handle data loading and Firestore calls itself. Keeping the logic here keeps the UI simple and makes the data flow easier to test and change later.

---

## How does it work? (Step by step)

1. `FoodViewModel` is created at app startup in `main.dart` via `MultiProvider`.
2. The constructor attaches a lifecycle observer (so it can detect when the app resumes) and then calls `fetchFoodData(reason: 'startup')`.
3. `fetchFoodData()` sets loading to true, clears any error, and asks `FoodRepository` for goals and entries.
4. After data loads, it schedules a midnight refresh timer so that at the next day's start (e.g., 12:00 AM), the data refreshes automatically.
5. If the repository calls succeed, the ViewModel updates `_dailyGoals` and `_dailyEntries` and tracks `_lastLoadedDate`.
6. It exposes computed totals for calories, protein, carbs, and fat by folding over the entries list.
7. If something fails, the ViewModel sets `_errorMessage` and logs the error.
8. `addFoodEntry(...)` builds a `FoodEntry` with quantity, unit, per-unit macros, and total macros, sends it to the repository, then refreshes the list from Firestore.
9. `updateDailyGoals(...)` writes new goals to Firestore and updates the local copy so the UI updates immediately.
10. `deleteFoodEntry(...)` deletes a single entry in Firestore and removes it from the local list.
11. When the app resumes (comes back from background), the lifecycle observer triggers `didChangeAppLifecycleState()` → `fetchFoodData(reason: 'resume')` to refresh the data immediately.
12. When midnight rolls over (the day changes), the timer fires → `_refreshForMidnight()` checks if the date changed, and if so, refreshes all data.
13. Every change ends with `notifyListeners()` so the UI rebuilds with the latest data.
14. When the ViewModel is disposed (app closes or the provider is torn down), it cancels the midnight timer and removes the lifecycle observer.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `ChangeNotifier` | A base class that lets the ViewModel say "I changed" |
| `notifyListeners()` | The signal that tells all watching widgets to rebuild |
| `Future` and `async/await` | A way to run work that takes time, like network calls |
| Repository | A separate class that is the only place allowed to talk to Firebase |
| `try/catch` | Error handling so failed network calls do not crash the app |
| `AppLogger` | A small debug logger used throughout the app |
| Computed getter | A value like `totalCalories` or `totalProtein` that is calculated from other data |
| `WidgetsBindingObserver` | A mixin that lets the ViewModel listen to app lifecycle events (foreground/background) |
| `AppLifecycleState.resumed` | The moment the app comes back to the foreground from the background |
| `Timer` | A one-time or repeating task scheduler. Here, used to refresh at midnight. |
| `_lastLoadedDate` | Tracks today's date string (YYYY-MM-DD). Used to detect when the day changes. |

---

## Code walkthrough

### Initial data load with lifecycle observer

```dart
FoodViewModel() {
  WidgetsBinding.instance.addObserver(this);
  _observerAttached = true;
  AppLogger.d('Food', 'FoodViewModel created');
  fetchFoodData(reason: 'startup');
}

Future<void> fetchFoodData({String reason = 'manual'}) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    AppLogger.d(
      'FoodViewModel',
      'Fetching food data (reason=$reason date=${_todayString()})',
    );
    _dailyGoals = await _repository.getDailyGoals();
    _dailyEntries = await _repository.getDailyFoodEntries();
    _lastLoadedDate = _todayString();
    AppLogger.d(
      'FoodViewModel',
      'Fetched ${_dailyEntries.length} entries for $_lastLoadedDate',
    );
  } catch (e, stack) {
    _errorMessage = 'Failed to load food data: $e';
    AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
  } finally {
    _isLoading = false;
    _scheduleMidnightRefresh();
    notifyListeners();
  }
}
```

**What this does:** On startup, the ViewModel attaches itself as an app lifecycle observer and calls `fetchFoodData()`. The `reason` parameter is just for logging so you can see if the data was refreshed due to startup, manual refresh, app resume, or midnight rollover. After every fetch (success or failure), it schedules a midnight refresh timer.

### Midnight refresh and app resume

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state != AppLifecycleState.resumed) return;
  AppLogger.d('Food', 'App resumed, refreshing food data');
  fetchFoodData(reason: 'resume');
}

Future<void> _refreshForMidnight() async {
  final today = _todayString();
  if (_lastLoadedDate == today) {
    AppLogger.d('Food', 'Midnight refresh skipped: already on $today');
    return;
  }

  AppLogger.d(
    'Food',
    'Midnight refresh triggered: $_lastLoadedDate -> $today',
  );
  await fetchFoodData(reason: 'midnight');
}

void _scheduleMidnightRefresh() {
  _midnightTimer?.cancel();

  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final delay = nextMidnight.difference(now);

  AppLogger.d(
    'Food',
    'Midnight refresh scheduled in ${delay.inMinutes}m ${delay.inSeconds % 60}s',
  );

  _midnightTimer = Timer(delay, () {
    AppLogger.d('Food', 'Midnight refresh timer fired');
    _refreshForMidnight();
  });
}
```

**What this does:** The lifecycle observer method runs when the app comes back to the foreground. If it's resumed, it refreshes the data right away with `reason: 'resume'`. The midnight refresh is scheduled to fire at the next day's start, so if it's still 11:45 PM, it waits 15 minutes before firing. When midnight hits, `_refreshForMidnight()` checks if the date actually changed (compare `_lastLoadedDate` vs today's date string), and if so, re-fetches the data to clear yesterday's entries.

### Adding a new entry

```dart
Future<void> addFoodEntry(
  String name,
  int quantity,
  String unit,
  int caloriesPerUnit,
  int proteinPerUnit,
  int carbsPerUnit,
  int fatPerUnit,
) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final totalCalories = quantity * caloriesPerUnit;
    final totalProtein = quantity * proteinPerUnit;
    final totalCarbs = quantity * carbsPerUnit;
    final totalFat = quantity * fatPerUnit;
    AppLogger.d(
      'FoodViewModel',
      'Adding food entry: $name qty=$quantity unit=$unit '
          'kcal=$totalCalories p=$totalProtein c=$totalCarbs f=$totalFat',
    );
    final entry = FoodEntry(
      id: '',
      name: name,
      quantity: quantity,
      unit: unit,
      caloriesPerUnit: caloriesPerUnit,
      proteinPerUnit: proteinPerUnit,
      carbsPerUnit: carbsPerUnit,
      fatPerUnit: fatPerUnit,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      timestamp: DateTime.now(),
    );

    await _repository.addFoodEntry(entry);
    _dailyEntries = await _repository.getDailyFoodEntries();
  } catch (e, stack) {
    _errorMessage = 'Failed to add food entry: $e';
    AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**What this does:** It builds a `FoodEntry` object, sends it to Firestore through the repository, then reloads the list so the new entry appears in the UI.

---

## What to do when you change this file

- [ ] Update the step list if you add or remove a public method
- [ ] Update the key concepts table if you add a new dependency
- [ ] Update the walkthrough snippets if the loading or error flow changes
- [ ] If the lifecycle observer or midnight refresh logic changes, update the "Midnight refresh and app resume" section
- [ ] If Firestore paths change, also update `24_feature_food.md`
- [ ] If you cancel the midnight timer or detach the observer, make sure `dispose()` is also updated
