# shanexplain — Change Ledger

This file is a running record of every update made to the `shanexplain/` documentation folder.
It is updated automatically whenever `/updateshanexplain` runs.

Each entry records **what docs changed**, **why**, and **what the underlying code change was**.

---

## Format

```
### [YYYY-MM-DD] — Short title of the change

**Code changed:** which source files were modified
**Docs updated:** which shanexplain/ files were affected
**Type:** update | new-file | architecture

Summary of what changed and why in 1–3 plain-English sentences.
```

---

## Log

_(Entries appear newest-first.)_

<!-- NEW ENTRIES GO HERE -->

### [2026-05-05] — Food macros and entry detail upgrade

**Code changed:** `lib/features/food/models/food_entry.dart`, `lib/features/food/repositories/food_repository.dart`, `lib/features/food/screens/widgets/add_food_modal.dart`, `lib/features/food/screens/widgets/set_goals_modal.dart`, `lib/features/food/viewmodels/food_viewmodel.dart`, `lib/features/home/screens/food_tab.dart`
**Docs updated:** `00_overview.md`, `06_screen_home.md`, `21_screen_food_tab.md`, `22_viewmodel_food.md`, `23_model_food_data.md`, `24_feature_food.md`
**Type:** update

Food logging now tracks quantity, units, and full macros (protein, carbs, fat) with live totals in the add modal. The Food tab UI was expanded to show macro summaries and richer entry cards, so the docs now describe the more advanced flow.

### [2026-05-04] — Food tab docs and header rule sync

**Code changed:** `CONSTITUTION.md`, `lib/features/auth/viewmodels/auth_viewmodel.dart`, `lib/features/food/models/daily_goals.dart`, `lib/features/food/models/food_entry.dart`, `lib/features/food/repositories/food_repository.dart`, `lib/features/food/screens/widgets/add_food_modal.dart`, `lib/features/food/screens/widgets/set_goals_modal.dart`, `lib/features/food/viewmodels/food_viewmodel.dart`, `lib/features/home/screens/food_tab.dart`, `lib/main.dart`
**Docs updated:** `00_overview.md`, `01_core_structure.md`, `02_core_entry_point.md`, `06_screen_home.md`, `13_shell_main.md`, `21_screen_food_tab.md`, `22_viewmodel_food.md`, `23_model_food_data.md`, `24_feature_food.md`, `INDEX.md`
**Type:** new-file

Food tracking now has real UI and data flow docs, so the Food tab, FoodViewModel, and repository are explained in plain English. The home shell and entry point docs now mention the FoodViewModel and the three-tab layout. The constitution header rule was also synced in code comments.

### [2026-05-04] — Auth session lock and walk sync tweaks

**Code changed:** `lib/features/auth/viewmodels/auth_viewmodel.dart`, `lib/features/home/viewmodels/walk_viewmodel.dart`
**Docs updated:** `12_viewmodel_auth.md`, `07_feature_auth.md`, `18_viewmodel_walk.md`, `11_full_flow.md`, `00_overview.md`
**Type:** update

Auth now claims a Firestore session lock and refreshes it so one account stays active on one device. Walk tracking now starts from Firestore, adds only the sensor delta, and resets cleanly when the user changes or the app resumes. The docs now explain the new lock and step-sync behavior in plain English.

### [2026-05-01] — Debug logging for Walk and routing

**Code changed:** `lib/shared/utils/app_logger.dart` (new), `lib/main.dart`, `lib/features/home/viewmodels/walk_viewmodel.dart`, `lib/features/home/screens/walk_tab.dart`
**Docs updated:** `20_core_app_logger.md` (new), `02_core_entry_point.md`, `18_viewmodel_walk.md`, `19_screen_walk_tab.md`
**Type:** new-file

A small `AppLogger` helper now centralizes debug-only logs so release builds stay quiet. Walk tracking and routing write tagged debug lines (boot, auth changes, sensor updates, and Firestore saves) to make development troubleshooting easier.

### [2026-04-30] — Walk tab: step counter, goal, and history

**Code changed:** `lib/features/home/screens/walk_tab.dart` (rewritten from placeholder), `lib/features/home/viewmodels/walk_viewmodel.dart` (new), `lib/features/home/models/day_steps.dart` (new), `lib/main.dart` (WalkViewModel registered), `lib/shell/main_shell.dart` (Walk tab added to nav bar), `android/app/src/main/AndroidManifest.xml` (ACTIVITY_RECOGNITION permission), `ios/Runner/Info.plist` (NSMotionUsageDescription), `pubspec.yaml` (pedometer, cloud_firestore, shared_preferences, permission_handler added)
**Docs updated:** `19_screen_walk_tab.md` (new), `18_viewmodel_walk.md` (new), `17_model_day_steps.md` (new), `02_core_entry_point.md` (updated), `01_core_structure.md` (updated), `06_screen_home.md` (updated), `00_overview.md` (updated), `11_full_flow.md` (updated), `INDEX.md` (updated)
**Type:** new-file

The Walk tab was built out from a placeholder into a fully working step counter. The phone's hardware pedometer is read via the `pedometer` package, permissions are requested at runtime, today's steps are calculated using a baseline subtraction trick, and all data is auto-saved to Firestore every 30 seconds. A `DaySteps` model class was introduced to hold history data, and `WalkViewModel` was registered as a third app-level provider in `main.dart`. The bottom nav bar was updated from two tabs (Home, Food) to three (Home, Food, Walk).

### [2026-04-30] — Profile screen, Settings screen, tappable drawer header

**Code changed:** `lib/features/profile/screens/profile_screen.dart` (new), `lib/features/settings/screens/settings_screen.dart` (new), `lib/shared/widgets/profile_drawer.dart`, `lib/features/home/screens/food_tab.dart` (minor text)
**Docs updated:** `14_ui_profile_drawer.md` (updated), `15_screen_profile.md` (new), `16_screen_settings.md` (new), `01_core_structure.md`, `08_feature_routing.md`, `00_overview.md`, `INDEX.md`
**Type:** new-file

Two new screens were added — a Profile Screen (shows avatar and email) and a Settings Screen (placeholder). The profile drawer header was upgraded from a static display to a tappable area that navigates to the Profile Screen; the Settings item now actually opens the Settings Screen instead of doing nothing. Both screens use push/pop navigation (`Navigator.push/pop`) rather than GoRouter — a new navigation pattern for this app, documented in `08_feature_routing.md`.

### [2026-04-29] — Feature-based folder restructure + shell with bottom navigation

**Code changed:** `lib/main.dart`, `lib/shell/main_shell.dart` (new), `lib/shell/navigation_viewmodel.dart` (new), `lib/features/auth/screens/` (moved), `lib/features/auth/viewmodels/auth_viewmodel.dart` (moved), `lib/features/home/screens/home_tab.dart` (new), `lib/features/home/screens/food_tab.dart` (new), `lib/shared/widgets/error_banner.dart` (moved), `lib/shared/widgets/profile_drawer.dart` (new), old `lib/screens/`, `lib/viewmodels/`, `lib/widgets/` folders deleted
**Docs updated:** `00_overview.md`, `01_core_structure.md`, `02_core_entry_point.md`, `03_screen_splash.md`, `06_screen_home.md`, `07_feature_auth.md`, `08_feature_routing.md`, `10_ui_error_banner.md`, `11_full_flow.md`, `12_viewmodel_auth.md`, `13_shell_main.md` (new), `14_ui_profile_drawer.md` (new), `INDEX.md`
**Type:** architecture

The flat `lib/screens/`, `lib/viewmodels/`, and `lib/widgets/` folders were replaced with a feature-based layout (`features/auth/`, `features/home/`, `shared/`, `shell/`). The old single `HomeScreen` was replaced by a shell layer (`MainShell`) with a bottom navigation bar containing two tabs — Home and Food. A `NavigationViewModel` was added to track the active tab, and a `ProfileDrawer` was added to hold the logout button and future profile actions.

### [2026-04-29] — Initial shanexplain documentation created

**Code changed:** All existing source files (first-time documentation run)
**Docs updated:** `00_overview.md`, `01_core_structure.md`, `02_core_entry_point.md`, `03_screen_splash.md`, `04_screen_login.md`, `05_screen_register.md`, `06_screen_home.md`, `07_feature_auth.md`, `08_feature_routing.md`, `09_ui_theme.md`, `10_ui_error_banner.md`, `11_full_flow.md`, `12_viewmodel_auth.md`
**Type:** new-file

All shanexplain documentation files were created for the first time. The project had already been refactored to use MVVM architecture (screens hand logic off to `AuthViewModel` instead of doing it themselves), GoRouter for navigation, and Firebase for auth. All docs were written to reflect this current state.
