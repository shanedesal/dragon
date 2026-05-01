# 10 — Error Banner Widget

> **File:** `lib/shared/widgets/error_banner.dart`
> **Category:** ui
> **Added:** 2026-04-29
> **Related files:** `04_screen_login.md`, `05_screen_register.md` (both use this widget)

---

## What is this?

`ErrorBannerWidget` is a small, reusable red box that shows an error message to the user. It has a red border, a slightly red-tinted background, a warning icon on the left, and the error text next to it.

It appears on the login and register screens when Firebase returns an error (e.g., wrong password, email already in use).

---

## Why does it exist?

Instead of writing the same red-box code in both `login_screen.dart` and `register_screen.dart`, it's extracted into its own widget file. This way:
- You only style it once.
- If you want to change how errors look, you change one file and both screens update.
- Code is easier to read — `ErrorBannerWidget(message: _errorMessage!)` is clearer than a blob of Container/Row/Icon code inline.

This is one of the most fundamental ideas in Flutter (and programming in general): **don't repeat yourself.**

---

## How does it work?

It's a `StatelessWidget` — it receives a `message` string and renders it. No logic, no state. Just display.

The widget:
1. Draws a `Container` with a red-tinted background and border (using `Color.fromRGBO` with low opacity to keep it subtle).
2. Puts a `Row` inside it: a red warning icon on the left, then the message text.
3. The text uses `Expanded` so it wraps properly on long messages instead of overflowing.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `StatelessWidget` | A widget with no state — it just takes inputs and renders them |
| `required` parameter | The caller MUST provide this value — the widget won't compile without it |
| `Color.fromRGBO(r, g, b, opacity)` | Creates a color from red/green/blue values plus an opacity (0.0 = invisible, 1.0 = solid) |
| `Expanded` | Tells a child inside a `Row` or `Column` to take up all remaining space |

---

## Code walkthrough

```dart
class ErrorBannerWidget extends StatelessWidget {
  const ErrorBannerWidget({super.key, required this.message});
  final String message;
```
**What this does:** Declares the widget and its one required input: `message`. The `required` keyword means whoever uses this widget must pass a message string.

```dart
decoration: BoxDecoration(
  color: Color.fromRGBO(243, 139, 168, 0.12),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: Color.fromRGBO(243, 139, 168, 0.35)),
),
```
**What this does:** `243, 139, 168` is the RGB value of `CatppuccinMocha.red`. `0.12` opacity gives the faint red tint for the background; `0.35` gives a more visible but still soft border. Using opacity instead of a solid red keeps it readable and not alarming.

---

## What to do when you change this file

- [ ] If you add more variants (e.g., a success banner, a warning banner), document each variant here and consider adding them to `INDEX.md` as separate entries or subsections
- [ ] If you change the color, update the code walkthrough
- [ ] If you add a dismiss/close button, add a step to the "How does it work" section and update the key concepts
