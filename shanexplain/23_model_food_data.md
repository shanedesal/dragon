# 23 - Food Data Models

> **Files:** `lib/features/food/models/food_entry.dart`, `lib/features/food/models/daily_goals.dart`
> **Category:** model
> **Added:** 2026-05-04
> **Related files:** `food_repository.dart`, `food_viewmodel.dart`, `21_screen_food_tab.md`, `24_feature_food.md`

---

## What is this?

These two classes are simple data containers for the Food feature:

- `FoodEntry` represents one food item the user logged, including quantity, unit, per-unit macros, and totals.
- `DailyGoals` represents the user's daily calorie and protein targets.

They are small, predictable shapes that make it easy to move data between Firestore and the UI.

---

## Why does it exist?

Raw Firestore data is just a map of key and value pairs. Using small model classes keeps the rest of the app clean and lets you add defaults in one place.

---

## How does it work? (Step by step)

1. When Firestore returns a document, `fromJson` converts it into a Dart object.
2. `FoodEntry.fromJson` reads quantity, unit, and totals. If older fields like `servingSize` or `calories` exist, it still accepts them for backward compatibility.
3. If per-unit values are missing, it calculates them from totals and quantity.
4. `FoodEntry.toJson` turns the object back into a map so Firestore can save it.
5. `DailyGoals.fromJson` reads `targetCalories` and `targetProtein`, with default values if the doc is missing.
6. `DailyGoals.toJson` writes those goals back to Firestore.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `final` | A value that cannot be changed after it is set |
| `factory` | A helper constructor that builds an object from data |
| `Map<String, dynamic>` | A flexible key/value map used to represent JSON data |
| `Timestamp` | Firestore's date type (it needs converting to `DateTime`) |
| Backward compatibility | Supporting older saved data so it still loads correctly |

---

## Code walkthrough

### `FoodEntry` conversion

```dart
factory FoodEntry.fromJson(Map<String, dynamic> json, String id) {
  final legacyServing = json['servingSize'] as String?;
  var quantity = json['quantity'] as int? ?? 1;
  var unit = json['unit'] as String? ?? 'serving';
  if (json['quantity'] == null && legacyServing != null && legacyServing.isNotEmpty) {
    unit = legacyServing;
  }
  final totalCalories = json['totalCalories'] as int?
      ?? json['calories'] as int?
      ?? 0;
  final caloriesPerUnit = json['caloriesPerUnit'] as int?
      ?? (quantity > 0 ? (totalCalories / quantity).round() : 0);

  return FoodEntry(
    id: id,
    name: json['name'] as String? ?? '',
    quantity: quantity,
    unit: unit,
    caloriesPerUnit: caloriesPerUnit,
    proteinPerUnit: json['proteinPerUnit'] as int? ?? 0,
    carbsPerUnit: json['carbsPerUnit'] as int? ?? 0,
    fatPerUnit: json['fatPerUnit'] as int? ?? 0,
    totalCalories: totalCalories,
    totalProtein: json['totalProtein'] as int? ?? 0,
    totalCarbs: json['totalCarbs'] as int? ?? 0,
    totalFat: json['totalFat'] as int? ?? 0,
    timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

Map<String, dynamic> toJson() {
  return {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'caloriesPerUnit': caloriesPerUnit,
    'proteinPerUnit': proteinPerUnit,
    'carbsPerUnit': carbsPerUnit,
    'fatPerUnit': fatPerUnit,
    'totalCalories': totalCalories,
    'totalProtein': totalProtein,
    'totalCarbs': totalCarbs,
    'totalFat': totalFat,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
```

**What this does:** `fromJson` supports both the new macro fields and older legacy fields like `servingSize` and `calories`. It also computes per-unit values if they are missing. `toJson` writes the full macro and total set back to Firestore.

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
