# 24 - Food Data Layer (Repository + Firestore)

> **File:** `lib/features/food/repositories/food_repository.dart`
> **Category:** feature
> **Added:** 2026-05-04
> **Related files:** `food_viewmodel.dart`, `food_entry.dart`, `daily_goals.dart`, `21_screen_food_tab.md`, `23_model_food_data.md`

---

## What is this?

`FoodRepository` is the only class that talks to Firestore for the Food feature. It saves entries, loads today's entries, and stores the user's daily goals.

Think of it like a courier. The UI and ViewModel hand it data, and it delivers that data to the database safely.

---

## Why does it exist?

Keeping Firebase calls in a single repository keeps the rest of the app clean. Screens and ViewModels stay focused on UI and state, not network rules or database paths.

---

## How does it work? (Step by step)

1. The repository checks the current user ID from `FirebaseAuth`. If there is no user, it throws an error.
2. `addFoodEntry` writes a new document to `users/{uid}/food_entries` using `FoodEntry.toJson()`.
3. `getDailyFoodEntries` queries only the current day by filtering the `timestamp` field.
4. `getDailyGoals` reads `users/{uid}/goals/daily_food`.
5. `setDailyGoals` writes back to the same goals document using `SetOptions(merge: true)`.
6. `deleteFoodEntry` removes a single entry document by its ID.
7. **`autoFillFoodEntry`** takes a partially-filled `FoodEntry` and sends it to an external nutrition API. The call now includes a **10-second timeout** so it doesn't hang forever, and it returns a sanitized error if something goes wrong.
8. The **`AddFoodModal`** was refactored into **6 smaller widgets** (`_ModalHeader`, `_CatalogBanner`, `_CatalogSection`, `_CatalogTile`, `_MacroFields`, and `_TotalsPreview`) to keep the code clean and manageable.
9. Every call is wrapped in `try/catch` and logs debug messages through `AppLogger`.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `FirebaseAuth` | The service that tells you who is logged in |
| `FirebaseFirestore` | The cloud database used by this app |
| `SetOptions(merge: true)` | Write data without deleting other fields in the same doc |
| `AppLogger` | A small debug logger used to trace writes and reads |
| HTTP POST request | A web request that sends data to an external server |
| Environment variables | Secret configuration values loaded from `.env` |
| `.timeout(Duration)` | Tells the app: "Stop waiting and throw an error if the server doesn't reply in X seconds" |

---

## Code walkthrough

### Load today's entries

```dart
final snapshot = await _firestore
    .collection('users')
    .doc(_uid)
    .collection('food_entries')
    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
    .orderBy('timestamp', descending: true)
    .get();
```

**What this does:** It limits the query to today, orders the results newest first, and converts each Firestore document into a `FoodEntry` object.

### Auto-fill with Timeout and Safety

```dart
try {
  final response = await http
      .post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
        body: jsonEncode({ ... }),
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    return FoodEntry.fromJson(jsonDecode(response.body), entry.id);
  } else {
    throw Exception('Autofill failed (server error ${response.statusCode}).');
  }
} on TimeoutException {
  throw Exception('Autofill timed out. Please try again.');
}
```

**What this does:** This method sends a request to an external API. The `.timeout(const Duration(seconds: 10))` is like setting a stopwatch — if the API doesn't answer in 10 seconds, it stops trying and throws a "timed out" error. Also, if the server returns an error, we now show a **sanitized message** like "server error 500" instead of leaking the entire messy technical error report to the user.

---

## What to do when you change this file

- [ ] Update the Firestore paths here if you rename collections or documents
- [ ] Update `23_model_food_data.md` if you add or rename fields
- [ ] If you add new repository methods, document them in this file
- [ ] If you add or remove environment variables, update `.env` and remind team members to also update their local `.env`
