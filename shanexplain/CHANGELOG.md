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
