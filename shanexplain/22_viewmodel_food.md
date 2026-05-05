# 22 - FoodViewModel

> **File:** `lib/features/food/viewmodels/food_viewmodel.dart`
> **Category:** feature
> **Added:** 2026-05-04
> **Related files:** `food_tab.dart`, `food_repository.dart`, `food_entry.dart`, `daily_goals.dart`, `24_feature_food.md`, `21_screen_food_tab.md`, `23_model_food_data.md`, `02_core_entry_point.md`

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
2. The constructor calls `fetchFoodData()` right away so the Food tab has data as soon as it appears.
3. `fetchFoodData()` sets loading to true, clears any error, and asks `FoodRepository` for goals and entries.
4. If the repository calls succeed, the ViewModel updates `_dailyGoals` and `_dailyEntries`.
5. It exposes computed totals for calories, protein, carbs, and fat by folding over the entries list.
6. If something fails, the ViewModel sets `_errorMessage` and logs the error.
7. `addFoodEntry(...)` builds a `FoodEntry` with quantity, unit, per-unit macros, and total macros, sends it to the repository, then refreshes the list from Firestore.
8. `updateDailyGoals(...)` writes new goals to Firestore and updates the local copy so the UI updates immediately.
9. `deleteFoodEntry(...)` deletes a single entry in Firestore and removes it from the local list.
10. Every change ends with `notifyListeners()` so the UI rebuilds with the latest data.

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

---

## Code walkthrough

### Initial data load

```dart
Future<void> fetchFoodData() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    AppLogger.d('FoodViewModel', 'Fetching food data...');
    _dailyGoals = await _repository.getDailyGoals();
    _dailyEntries = await _repository.getDailyFoodEntries();
    AppLogger.d('FoodViewModel', 'Fetched ${_dailyEntries.length} entries for today.');
  } catch (e, stack) {
    _errorMessage = 'Failed to load food data: $e';
    AppLogger.d('FoodViewModel', _errorMessage!, error: e, stackTrace: stack);
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**What this does:** It flips on the loading flag, asks the repository for goals and entries, then turns loading off. If something goes wrong, it stores a friendly error message so the UI can show it.

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
- [ ] If Firestore paths change, also update `24_feature_food.md`
