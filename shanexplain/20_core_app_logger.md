# 20 - AppLogger (Debug Logging)

> **File:** `lib/shared/utils/app_logger.dart`
> **Category:** core
> **Added:** 2026-05-01
> **Related files:** `main.dart`, `walk_viewmodel.dart`, `walk_tab.dart`

---

## What is this?

`AppLogger` is a tiny helper for writing debug logs with a tag. It wraps Dart's `developer.log` so you can see what the app is doing while you test, without sprinkling raw logging calls everywhere.

---

## Why does it exist?

It keeps logging consistent and easy to remove from release builds. When the app is not in debug mode, it returns early and logs nothing, so you get clean production output.

---

## How does it work? (Step by step)

1. Code calls `AppLogger.d('Tag', 'Message')` from anywhere in the app.
2. `AppLogger` checks `kDebugMode`. If the app is not a debug build, it exits right away.
3. If it is a debug build, it forwards the message to `developer.log` with the tag and optional `error` and `stackTrace`.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `kDebugMode` | A Flutter constant that is `true` only in debug builds |
| `developer.log` | Dart's built-in logging function that writes to the debug console |
| `StackTrace` | A breadcrumb trail that shows where an error came from |
| `AppLogger.d` | The helper method you call to write a tagged debug log |

---

## Code walkthrough

```dart
static void d(
  String tag,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  if (!kDebugMode) return;
  developer.log(
    message,
    name: tag,
    error: error,
    stackTrace: stackTrace,
  );
}
```

**What this does:** The method takes a short tag and a message. If the app is running in debug mode, it writes the message to the console with the tag and any error details. If the app is running in release mode, it exits immediately and prints nothing.

---

## What to do when you change this file

- [ ] Update the "How does it work" steps if the log behavior changes
- [ ] Update the "Key concepts" table if new inputs or packages are added
- [ ] Update the code walkthrough if the method body changes
- [ ] Add any new related files that start using `AppLogger`
