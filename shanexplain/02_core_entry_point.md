# main.dart — The Entry Point of the Entire App

> ⚠️ **Architecture updated 2026-04-30:** Added `WalkViewModel` as a third registered provider alongside `AuthViewModel` and `NavigationViewModel`.

`lib/main.dart` is the **first file that runs** when your app launches. Think of it as the front door of your house — everything starts here.

---

## Section 1: The `main()` Function

```dart
void main() async {
  AppLogger.d('App', 'Bootstrapping');
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.d('App', 'Firebase initialize start');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppLogger.d('App', 'Firebase initialize done');
  await dotenv.load(fileName: '.env');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(create: (_) => WalkViewModel()),
        ChangeNotifierProvider(create: (_) => FoodViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}
```

**In plain English:**

1. `void main()` — This is the starting function. Flutter runs this first, always.
2. `AppLogger.d(...)` — Writes debug-only messages so you can see the boot process in the console. These logs do nothing in release builds.
3. `WidgetsFlutterBinding.ensureInitialized()` — Makes sure Flutter's internal engine is ready before you do anything else. Required whenever you do something before `runApp`.
4. `await Firebase.initializeApp(...)` — Connects the app to your Firebase project in the cloud. The `await` means "wait here until this is done before continuing."
5. `await dotenv.load(fileName: '.env')` — Loads environment variables (like API keys and URLs) from a `.env` file into the app. This keeps secrets out of the source code. Features like food autofill use these values to call external APIs safely.
6. `MultiProvider(providers: [...], child: const MyApp())` — Sets up **four** shared state managers at the very top of the app. Think of it like four bulletin boards hung at the entrance of the building — every room inside can read from any of them.
   - `AuthViewModel` — manages all login/register/logout logic and the current user.
   - `NavigationViewModel` — tracks which bottom navigation tab is currently selected.
   - `WalkViewModel` — manages step counting, daily step goal, and step history. Registered here so the Walk tab can access it via `context.watch`/`context.read`.
  - `FoodViewModel` — manages food entries and daily calorie/protein goals. Registered here so the Food tab can access it via `context.watch`/`context.read`.
7. `runApp(...)` — Hands control to your `MyApp` widget, which is the root of everything the user sees.

> **What is `MultiProvider`?** It's just a convenience wrapper that lets you register multiple providers at once instead of nesting them inside each other. Same result, cleaner code.

---

## Section 2: The Auth Notifier

```dart
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance
        .authStateChanges()
        .listen((user) {
          AppLogger.d(
            'Auth',
            'Auth state changed: uid=${user?.uid ?? 'null'} '
                'email=${user?.email ?? 'null'}',
          );
          notifyListeners();
        });
  }
}

final _authNotifier = _AuthNotifier();
```

**In plain English:**

This is a "watcher." Firebase can tell your app whenever a user logs in or logs out. This class listens to those events and then says "hey router, something changed — check your rules again."

- `authStateChanges()` — A stream (like a live feed) from Firebase. Fires an event every time login state changes.
- `notifyListeners()` — Tells anything that's watching this object: "wake up and re-check."
- The router is set up to listen to this, so it automatically redirects the user when they log in or out. The `AppLogger` line is just a debug breadcrumb so you can see auth changes in the console while developing.

---

## Section 3: The Router

```dart
final _router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final path = state.matchedLocation;
    final onSplash = path == '/splash';
    final onAuthRoute = path == '/login' || path == '/register';

    AppLogger.d(
      'Router',
      'Redirect check: path=$path authed=$isAuthenticated '
          'onSplash=$onSplash onAuth=$onAuthRoute',
    );

    if (onSplash) return null;
    if (isAuthenticated && onAuthRoute) return '/home';
    if (!isAuthenticated && !onAuthRoute) return '/login';
    return null;
  },
  routes: [ ... ],
);
```

**In plain English:**

The router is like a **traffic cop** for your app. It decides which screen to show based on where you are and whether you're logged in.

- `initialLocation: '/splash'` — Always start at the splash screen.
- `refreshListenable: _authNotifier` — Every time auth state changes, re-run the redirect logic.
- The `redirect` function runs before every navigation and asks: "Should I let this person go where they're trying to go, or redirect them?"

### The redirect rules:
1. If you're on the splash screen → do nothing (let the splash play)
2. If you're **logged in** and trying to go to login/register → send you to `/home` instead
3. If you're **NOT logged in** and trying to go somewhere other than login/register → send you to `/login`
4. Otherwise → let you go wherever you asked

This means a logged-in user can never accidentally land on the login page, and a logged-out user can never access the home screen.

The `AppLogger` line inside `redirect` is a debug-only log so you can see each routing decision during development.

---

## Section 4: Route Definitions

```dart
routes: [
  GoRoute(path: '/splash',   builder: (_, __) => const SplashScreen()),
  GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
  GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
  GoRoute(path: '/home',     builder: (_, __) => const MainShell()),
],
```

**In plain English:**

This is the app's **map**. It says: "when the URL/path is `/login`, show the `LoginScreen`." Each path maps to one screen. Note that `/home` now points to `MainShell` — the outer frame with the bottom nav bar — instead of the old `HomeScreen`. The actual tab content (`HomeTab`, `FoodTab`) lives inside `MainShell`.

---

## Section 5: The MyApp Widget

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dragon',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

**In plain English:**

`MyApp` is the root widget — the outermost container that wraps everything.

- `MaterialApp.router` — Uses Material Design (Google's design system) with routing support.
- `theme: AppTheme.darkTheme` — Applies the dark color theme from `app_theme.dart` to the entire app.
- `routerConfig: _router` — Plugs in the router you defined above.
- `debugShowCheckedModeBanner: false` — Hides the red "DEBUG" banner in the top-right corner during development.
