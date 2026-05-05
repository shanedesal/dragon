# 23 - Food Data Models

> **Files:** `lib/features/food/models/food_entry.dart`, `lib/features/food/models/daily_goals.dart`
> **Category:** model
> **Added:** 2026-05-04
> **Related files:** `food_repository.dart`, `food_viewmodel.dart`, `21_screen_food_tab.md`, `24_feature_food.md`

---

## What is this?

These two classes are simple data containers for the Food feature:

- `FoodEntry` represents one food item the user logged.
- `DailyGoals` represents the user's daily calorie and protein targets.

They are small, predictable shapes that make it easy to move data between Firestore and the UI.

---

## Why does it exist?

Raw Firestore data is just a map of key and value pairs. Using small model classes keeps the rest of the app clean and lets you add defaults in one place.

---

## How does it work? (Step by step)

1. When Firestore returns a document, `fromJson` converts it into a Dart object.
2. `FoodEntry.fromJson` reads name, calories, serving size, and timestamp. If any value is missing, it falls back to a safe default.
3. `FoodEntry.toJson` turns the object back into a map so Firestore can save it.
4. `DailyGoals.fromJson` reads `targetCalories` and `targetProtein`, with default values if the doc is missing.
5. `DailyGoals.toJson` writes those goals back to Firestore.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `final` | A value that cannot be changed after it is set |
| `factory` | A helper constructor that builds an object from data |
| `Map<String, dynamic>` | A flexible key/value map used to represent JSON data |
| `Timestamp` | Firestore's date type (it needs converting to `DateTime`) |

---

## Code walkthrough

### `FoodEntry` conversion

```dart
factory FoodEntry.fromJson(Map<String, dynamic> json, String id) {
  return FoodEntry(
    id: id,
    name: json['name'] as String? ?? '',
    calories: json['calories'] as int? ?? 0,
    servingSize: json['servingSize'] as String? ?? '',
    timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

Map<String, dynamic> toJson() {
  return {
    'name': name,
    'calories': calories,
    'servingSize': servingSize,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
```

**What this does:** `fromJson` builds a `FoodEntry` from Firestore data. `toJson` does the reverse so the entry can be saved again. The timestamp is converted both ways because Firestore uses `Timestamp` while the app uses `DateTime`.

### `DailyGoals` defaults

```dart
factory DailyGoals.fromJson(Map<String, dynamic> json) {
  return DailyGoals(
    targetCalories: json['targetCalories'] as int? ?? 2000,
    targetProtein: json['targetProtein'] as int? ?? 100,
  );
}
```

**What this does:** If the goals document does not exist yet, the model still returns sensible defaults so the UI has something to show.

---

## What to do when you change this file

- [ ] Update defaults here if you change the app's default goals
- [ ] If you add new fields (like carbs), add them to both `fromJson` and `toJson`
- [ ] Update `24_feature_food.md` if Firestore field names change
