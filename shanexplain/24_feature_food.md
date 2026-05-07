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
2. `addFoodEntry` writes a new document to `users/{uid}/food_entries` using `FoodEntry.toJson()` (including quantity, unit, and macro totals).
3. `getDailyFoodEntries` queries only the current day by filtering the `timestamp` field between the start and end of today. Results are sorted newest first.
4. `getDailyGoals` reads `users/{uid}/goals/daily_food`. If the doc is missing, it returns defaults from `DailyGoals`.
5. `setDailyGoals` writes back to the same goals document using `SetOptions(merge: true)` so it does not wipe other fields.
6. `deleteFoodEntry` removes a single entry document by its ID.
7. `autoFillFoodEntry` takes a partially-filled `FoodEntry` and sends an HTTP POST request to an external nutrition API (using URL and API key from environment variables loaded by `flutter_dotenv`). The API returns nutrition data for the food, which is converted back to a `FoodEntry` and returned.
8. Every call is wrapped in `try/catch` and logs debug messages through `AppLogger`.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `FirebaseAuth` | The service that tells you who is logged in |
| `FirebaseFirestore` | The cloud database used by this app |
| Collection and document paths | The "folders" and "files" inside Firestore |
| `Timestamp` | Firestore's date type for queries and sorting |
| `SetOptions(merge: true)` | Write data without deleting other fields in the same doc |
| `try/catch` | Error handling so a failed write does not crash the app |
| `AppLogger` | A small debug logger used to trace writes and reads |
| HTTP POST request | A web request that sends data to an external server and waits for a response |
| Environment variables | Secret configuration values (like API keys) loaded from `.env` and kept out of source code |
| `dotenv` | A package that loads environment variables from a `.env` file into the app |

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

final entries = snapshot.docs
    .map((doc) => FoodEntry.fromJson(doc.data(), doc.id))
    .toList();
```

**What this does:** It limits the query to today, orders the results newest first, and converts each Firestore document into a `FoodEntry` object.

### Auto-fill a food entry from an external API

```dart
Future<FoodEntry> autoFillFoodEntry(FoodEntry entry) async {
  final apiUrl = dotenv.get('AUTOFILLURL');
  final apiKey = dotenv.get('AUTOFILLKEY');
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    },
    body: jsonEncode({
      ...entry.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    }),
  );
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return FoodEntry.fromJson(json, entry.id);
  } else {
    throw Exception(
      'Failed to auto-fill food entry: ${response.statusCode} ${response.body}',
    );
  }
}
```

**What this does:** The method retrieves the nutrition API's URL and API key from environment variables (managed by `flutter_dotenv`). It builds an HTTP POST request with the food entry data and sends it to the external API. If the response is successful (status code 200), it parses the JSON response and converts it back to a `FoodEntry`. If the API returns an error, it throws an exception with the error details. The ViewModel catches this exception and shows an error message to the user.

---

## What to do when you change this file

- [ ] Update the Firestore paths here if you rename collections or documents
- [ ] Update `23_model_food_data.md` if you add or rename fields
- [ ] If you add new repository methods, document them in this file
- [ ] If the autofill API endpoint changes, update the method and this walkthrough
- [ ] If you add or remove environment variables, update `.env` and remind team members to also update their local `.env`
