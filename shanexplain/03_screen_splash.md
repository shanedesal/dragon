# 03 — Splash Screen

> **File:** `lib/features/auth/screens/splash_screen.dart`
> **Category:** screen
> **Added:** 2026-04-29
> **Related files:** `main.dart` (navigates away from splash after 2.8 s)

---

## What is this?

The splash screen is the very first thing the user sees when they open the app. It plays a short animation — the logo fades in and scales up, then the app name slides up below it — and then automatically sends the user to the login page after about 2.8 seconds.

Think of it like the loading screen before a video game's main menu.

---

## Why does it exist?

Two reasons:
1. **Branding** — it gives the app a polished, professional feel on launch.
2. **Buying time** — Firebase needs a moment to initialize and check if the user is already logged in. The splash screen covers that gap gracefully instead of showing a blank screen.

---

## How does it work? (Step by step)

1. **The screen loads** — `initState()` runs automatically when the widget first appears.
2. **An animation controller is created** — it's set to run for 1800 milliseconds (1.8 seconds) total.
3. **Four animations are defined** on a timeline:
   - 0%–55% of the timeline: the logo fades in and scales up from 70% to 100% size.
   - 45%–95% of the timeline: the app name fades in and slides upward.
4. **The controller starts** (`_controller.forward()`), playing all animations.
5. **A timer is set** for 2800 ms (2.8 seconds). When it fires, the app navigates to `/login`.
6. The router's redirect rules in `main.dart` then check if the user is already logged in and may redirect to `/home` instead.

---

## Key concepts used

| Concept | Plain-English meaning |
|---------|-----------------------|
| `StatefulWidget` | A widget that has internal state (variables that can change and trigger a redraw) |
| `AnimationController` | The engine that drives animations — it counts from 0.0 to 1.0 over a set duration |
| `CurvedAnimation` | Wraps a controller and makes the animation speed up/slow down non-linearly (feels more natural) |
| `Tween` | Defines the start and end values of an animation (e.g., scale from 0.7 to 1.0) |
| `Interval` | Says "this animation only plays during this slice of the timeline" |
| `FadeTransition` | A widget that reads an animation value and adjusts its child's opacity |
| `ScaleTransition` | A widget that reads an animation value and adjusts its child's size |
| `SlideTransition` | A widget that reads an animation value and moves its child |
| `Future.delayed` | Wait X milliseconds, then run some code |
| `SingleTickerProviderStateMixin` | Required by `AnimationController` — provides the timing heartbeat |

---

## Code walkthrough

```dart
_controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1800),
);
```
**What this does:** Creates the animation engine. It will count from 0.0 → 1.0 over 1800 ms. `vsync: this` ties it to the screen's refresh rate so it doesn't waste CPU when the screen isn't visible.

```dart
_logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  ),
);
```
**What this does:** The logo starts at 70% size and grows to 100%. The `easeOutBack` curve means it slightly overshoots 100% then snaps back — a subtle "pop" effect. This only plays during the first 55% of the total animation timeline.

```dart
Future.delayed(const Duration(milliseconds: 2800), () {
  if (mounted) context.go('/login');
});
```
**What this does:** After 2.8 seconds, navigate to `/login`. The `if (mounted)` check makes sure the widget is still on screen before trying to navigate — avoids crashes if the user somehow left the screen early.

---

## What to do when you change this file

- [ ] If you change the animation duration or timing, update the "How does it work" step 3
- [ ] If you add new animations, add them to the "Key concepts" table and the code walkthrough
- [ ] If you change the delay before navigating away, update step 5
