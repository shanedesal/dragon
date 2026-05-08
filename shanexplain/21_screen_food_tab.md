# 21 - Food Tab Screen

> **Files:** `lib/features/food/screens/food_tab.dart`, `lib/features/food/screens/widgets/add_food_modal.dart`, `lib/features/food/screens/widgets/set_goals_modal.dart`
> **Category:** screen
> **Added:** 2026-05-04
> **Related files:** `food_viewmodel.dart`, `food_repository.dart`, `food_entry.dart`, `daily_goals.dart`, `22_viewmodel_food.md`, `23_model_food_data.md`, `24_feature_food.md`, `06_screen_home.md`, `13_shell_main.md`

---

## What is this?

The Food tab is a daily food diary with macro tracking (protein, carbs, fat). It shows calorie and protein progress, a macro summary, and a list of meals with their totals.

The add-food panel also includes an autofill button in the header. Right now it is a placeholder for future auto-entry help.

The screen reads everything from `FoodViewModel`, so it never talks to Firestore directly.

---

## Why does it exist?

Food tracking is a core part of a fitness app. This screen gives the user one simple place to log meals and see progress without jumping between screens.

---

## How does it work? (Step by step)

1. The shell shows `FoodTab()` as the second tab in the bottom bar.
2. `FoodTab` watches `FoodViewModel` with `context.watch`, so it rebuilds when food data changes.
3. If the ViewModel is loading and there are no entries yet, the tab shows a centered spinner.
4. The main body is a `CustomScrollView` wrapped in a `RefreshIndicator`. Pulling down logs a debug line and calls `vm.fetchFoodData()` to reload goals and entries.
5. If `vm.errorMessage` is not null, an `ErrorBannerWidget` appears at the top.
6. **`_SummaryCard`** is a dedicated widget that shows calories and protein progress, plus how much is left for each goal. The pencil icon opens `SetGoalsModal` to edit goals.
7. **`_MacroCard`** is a dedicated widget that shows totals for protein, carbs, and fat for the day.
8. The entries section either shows an empty state with a "Log your first meal" button or a list of cards, one per `FoodEntry`.
9. Each entry card shows the name, serving info, macro totals, calories, and time. The delete button calls `vm.deleteFoodEntry(entry.id)`.
10. Tapping the floating plus button opens `AddFoodModal`. The modal collects quantity, unit, and per-unit macros, shows a live total, and includes an autofill button in the header. Submitting the form calls `vm.addFoodEntry(...)`.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `StatelessWidget` | A widget that does not hold its own local state |
| `context.watch<T>()` | Listen to a ViewModel and rebuild when it changes |
| `context.read<T>()` | Read a ViewModel one time for an action |
| `RefreshIndicator` | Pull down to refresh a scroll view |
| `CustomScrollView` + `SliverList` | A flexible scroll view that can mix headers and lists |
| `AlwaysScrollableScrollPhysics` | Keeps pull-to-refresh working even when the list is short |
| `FloatingActionButton` | The round "plus" button in the bottom corner |
| `showModalBottomSheet` | A panel that slides up from the bottom of the screen |
| `TextFormField` + validators | A text field with built-in form validation |
| `DropdownButtonFormField` | A drop-down picker used here for units like g or ml |
| `LinearProgressIndicator` | A horizontal progress bar |
| `ErrorBannerWidget` | A reusable red error box used across the app |

---

## Code walkthrough

### The loading gate and refresh

```dart
child: vm.isLoading && vm.dailyEntries.isEmpty
    ? const Center(child: CircularProgressIndicator(color: CatppuccinMocha.mauve))
    : RefreshIndicator(
        color: CatppuccinMocha.mauve,
        onRefresh: () => vm.fetchFoodData(),
        child: CustomScrollView(
          slivers: [
```

**What this does:** If the ViewModel is still loading and there are no entries yet, the screen shows a spinner instead of empty UI. Once data is ready, the `RefreshIndicator` wraps the scroll view so a pull-down gesture reloads the food data.

### The summary card (Extracted Widget)

```dart
class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final calorieProgress = calorieGoal > 0 ? vm.totalCalories / calorieGoal : 0.0;
    ...
    return Container(
      ...
      child: Column(
        children: [
          _ProgressRow(
            label: 'Calories',
            current: vm.totalCalories,
            goal: calorieGoal,
            progress: calorieProgress,
            color: calorieProgress >= 1.0 ? CatppuccinMocha.red : CatppuccinMocha.mauve,
            unit: 'kcal',
          ),
          ...
        ],
      ),
    );
  }
}
```

**What this does:** The summary card was moved from a messy function into its own `StatelessWidget` class. This makes the code easier to maintain and helps Flutter's performance. Each `_ProgressRow` inside it tracks progress and switches to red if you go over your calorie goal.

### The live totals preview

```dart
final totalCalories = quantity * caloriesPerUnit;
final totalProtein = quantity * proteinPerUnit;
final totalCarbs = quantity * carbsPerUnit;
final totalFat = quantity * fatPerUnit;

Text(
  '$totalCalories kcal • P $totalProtein g • C $totalCarbs g • F $totalFat g',
)
```

**What this does:** As the user types, the modal multiplies the per-unit values by the quantity and shows the totals live. That makes it easier to log real meals without doing math in your head.

---

## What to do when you change this file

- [ ] Update the step list if you add or remove a section of the screen
- [ ] Update the key concepts table if you add a new widget or package
- [ ] Update the walkthrough snippets if the loading gate or progress math changes
- [ ] If you add new modals, document them here and link to them in Related files files
