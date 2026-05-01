# 17 — DaySteps Model

> **File:** `lib/features/home/models/day_steps.dart`
> **Category:** feature
> **Added:** 2026-04-30
> **Related files:** `walk_viewmodel.dart`, `walk_tab.dart`, `18_viewmodel_walk.md`, `19_screen_walk_tab.md`

---

## What is this?

`DaySteps` is a tiny data container — a labelled box that holds exactly three things about a single day:
- The **date** (written as a text string like `"2026-04-30"`)
- The **step count** for that day
- The **step goal** that was set that day

It doesn't do anything by itself. It just holds information so other parts of the app can pass it around cleanly.

> **What is a "model"?** In programming, a *model* is a simple object whose only job is to represent a piece of data — like a row in a spreadsheet. This one represents one row of step history.

---

## Why does it exist?

When the app loads step history from Firebase, it gets back a list of raw numbers. Instead of passing those raw numbers around everywhere, we wrap each day's data in a `DaySteps` object. That way, any piece of code that receives a `DaySteps` knows exactly what's inside, and you can write `day.steps` instead of remembering which position in an array holds the step count.

It also makes the code self-documenting — `DaySteps(date: '2026-04-30', steps: 8200, goal: 10000)` is much easier to read than a bare map like `{'date': '...', 'steps': 8200, ...}`.

---

## How does it work? (Step by step)

1. **`WalkViewModel` fetches data from Firestore** — each Firestore document contains `steps`, `goal`, and the document ID is the date string.
2. **`WalkViewModel` converts each document into a `DaySteps`** — `DaySteps(date: doc.id, steps: data['steps'], goal: data['goal'])`.
3. **The list of `DaySteps` objects is stored in `WalkViewModel.history`**.
4. **`WalkTab` reads that list** and passes each `DaySteps` to a `_HistoryItem` widget, which uses `day.steps`, `day.goal`, and `day.date` to build the row on screen.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `class` | A blueprint — defines what a thing looks like and what data it holds |
| `final` | A field that can only be set once (when the object is created) and never changed |
| `const` constructor | Means instances of this class can be created at compile time, which is a tiny performance win |
| Model class | A class whose only job is to hold data — no methods, no logic, just fields |

---

## Code walkthrough

```dart
class DaySteps {
  final String date; // YYYY-MM-DD
  final int steps;
  final int goal;

  const DaySteps({
    required this.date,
    required this.steps,
    required this.goal,
  });
}
```

**What this does:**
- `class DaySteps` — declares a new type called `DaySteps`.
- The three `final` fields (`date`, `steps`, `goal`) are the only data it holds. `final` means once you set them, they never change — this object is *immutable* (frozen in time).
- The `const DaySteps({...})` constructor is how you create one. The `required` keyword means all three fields must be provided — you can't accidentally forget the date or the goal.
- Because it's `const`, Flutter can reuse identical objects in memory instead of creating new ones. For a history list this small, it's a minor win, but it's a good habit.

---

## What to do when you change this file

- [ ] If you add a new field (e.g. `distance` or `calories`), update step 2 in "How does it work?" and the `WalkViewModel` that creates `DaySteps` objects.
- [ ] Update the code walkthrough if the constructor changes.
- [ ] Update `19_screen_walk_tab.md` if the new field is displayed anywhere on screen.
