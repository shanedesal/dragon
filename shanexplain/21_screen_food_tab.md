# 21 - Food Tab Screen

> **Files:** `lib/features/home/screens/food_tab.dart`, `lib/features/food/screens/widgets/add_food_modal.dart`, `lib/features/food/screens/widgets/set_goals_modal.dart`
> **Category:** screen
> **Added:** 2026-05-04
> **Related files:** `food_viewmodel.dart`, `food_repository.dart`, `food_entry.dart`, `daily_goals.dart`, `22_viewmodel_food.md`, `23_model_food_data.md`, `24_feature_food.md`, `06_screen_home.md`, `13_shell_main.md`

---

## What is this?

The Food tab is a daily food diary. It lets the user see how many calories they have logged today, what foods they added, and it gives quick buttons to add an entry or change goals.

The screen reads everything from `FoodViewModel`, so it never talks to Firestore directly.

---

## Why does it exist?

Food tracking is a core part of a fitness app. This screen gives the user one simple place to log meals and see progress without jumping between screens.

---

## How does it work? (Step by step)

1. The shell shows `FoodTab()` as the second tab in the bottom bar.
2. `FoodTab` watches `FoodViewModel` with `context.watch`, so it rebuilds when food data changes.
3. If the ViewModel is loading and there are no entries yet, the tab shows a centered spinner.
4. The main body is a `CustomScrollView` wrapped in a `RefreshIndicator`. Pulling down calls `vm.fetchFoodData()` to reload goals and entries.
5. If `vm.errorMessage` is not null, an `ErrorBannerWidget` appears at the top.
6. The progress card reads `vm.dailyGoals` and `vm.totalCalories`, then shows "Eaten", "Remaining", and a progress bar.
7. The entries section either shows an empty message or a list of cards, one per `FoodEntry`. Each card has a delete button that calls `vm.deleteFoodEntry(entry.id)`.
8. Tapping the pencil icon opens `SetGoalsModal`. The modal pre-fills the current goals and calls `vm.updateDailyGoals(...)` when you save.
9. Tapping the floating plus button opens `AddFoodModal`. The modal validates the form and calls `vm.addFoodEntry(...)`, then closes.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `StatelessWidget` | A widget that does not hold its own local state |
| `context.watch<T>()` | Listen to a ViewModel and rebuild when it changes |
| `context.read<T>()` | Read a ViewModel one time for an action |
| `RefreshIndicator` | Pull down to refresh a scroll view |
| `CustomScrollView` + `SliverList` | A flexible scroll view that can mix headers and lists |
| `FloatingActionButton` | The round "plus" button in the bottom corner |
| `showModalBottomSheet` | A panel that slides up from the bottom of the screen |
| `TextFormField` + validators | A text field with built-in form validation |
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

### The progress math

```dart
final caloriesLeft = vm.dailyGoals.targetCalories - vm.totalCalories;
final progress = vm.totalCalories /
    (vm.dailyGoals.targetCalories > 0 ? vm.dailyGoals.targetCalories : 1);

LinearProgressIndicator(
  value: progress.clamp(0.0, 1.0),
  backgroundColor: CatppuccinMocha.surface1,
  color: progress >= 1.0 ? CatppuccinMocha.red : CatppuccinMocha.green,
  minHeight: 8,
  borderRadius: BorderRadius.circular(4),
),
```

**What this does:** The card computes how much of the calorie goal is used and turns it into a 0 to 1 progress value. The bar clamps the value so it never overflows past 100%. If you go over the goal, the bar turns red.

---

## What to do when you change this file

- [ ] Update the step list if you add or remove a section of the screen
- [ ] Update the key concepts table if you add a new widget or package
- [ ] Update the walkthrough snippets if the loading gate or progress math changes
- [ ] If you add new modals, document them here and link to them in Related files
