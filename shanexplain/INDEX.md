# shanexplain — Master Index

This folder contains plain-English explanations of the **Dragon** Flutter project.
It is meant to grow alongside the codebase. Every time a new screen, feature, or piece of UI is added, a corresponding file should be added here.

---

## Naming Convention

```
[nn]_[category]_[topic].md
```

| Part | Meaning | Example values |
|------|---------|----------------|
| `nn` | Two-digit order number (for sorting) | `03`, `10`, `14` |
| `category` | What kind of thing this explains | `core`, `screen`, `feature`, `ui` |
| `topic` | Specific name of the file/screen/feature | `auth`, `home`, `routing` |

**Categories:**
- `core` — App-level setup: structure, entry point, pubspec
- `screen` — Individual screens the user sees
- `feature` — A behaviour or system (auth, notifications, etc.)
- `ui` — Visual pieces: theme, reusable widgets, icons

**Examples:**
- Adding a new screen called "Profile" → `07_screen_profile.md`
- Adding push notifications → `12_feature_notifications.md`
- Adding a new reusable card widget → `11_ui_card_widget.md`

**Numbering tip:** Leave gaps of ~2 between numbers within a category so you can insert files later without renumbering everything. E.g., `03`, `05`, `07` for screens.

---

## Adding a New File

1. Copy `_TEMPLATE.md` into this folder
2. Rename it following the convention above
3. Fill in the sections (the template has prompts for each one)
4. Add a row to the **File List** table below

---

## File List

### Meta
| File | What it covers |
|------|---------------|
| `INDEX.md` | This file — master index and contribution guide |
| `_TEMPLATE.md` | Blank template to copy when adding new explanations |
| [CHANGELOG.md](CHANGELOG.md) | Running log of every update made to this folder |

### Core — App Setup
| File | What it covers |
|------|---------------|
| [00_overview.md](00_overview.md) | What the app is, the big-picture flow |
| [01_core_structure.md](01_core_structure.md) | Every folder and file in the project |
| [02_core_entry_point.md](02_core_entry_point.md) | `main.dart` — how the app boots up |

### Screens — What the User Sees
| File | What it covers |
|------|---------------|
| [03_screen_splash.md](03_screen_splash.md) | Splash / intro animation screen |
| [04_screen_login.md](04_screen_login.md) | Login form screen |
| [05_screen_register.md](05_screen_register.md) | Registration form screen |
| [06_screen_home.md](06_screen_home.md) | Shell + tabs after logging in (MainShell, HomeTab, FoodTab) |

### Shell — The Permanent App Frame
| File | What it covers |
|------|---------------|
| [13_shell_main.md](13_shell_main.md) | `MainShell` and `NavigationViewModel` — the outer frame and tab switching |

### Features — How Things Work Under the Hood
| File | What it covers |
|------|---------------|
| [07_feature_auth.md](07_feature_auth.md) | Firebase Authentication: login, register, logout |
| [08_feature_routing.md](08_feature_routing.md) | GoRouter: navigation and redirect guards |

### ViewModels — Business Logic (MVVM)
| File | What it covers |
|------|---------------|
| [12_viewmodel_auth.md](12_viewmodel_auth.md) | `AuthViewModel`: all auth logic, loading state, error handling |

### UI — Visual Building Blocks
| File | What it covers |
|------|---------------|
| [09_ui_theme.md](09_ui_theme.md) | Catppuccin Mocha color palette and app theming |
| [10_ui_error_banner.md](10_ui_error_banner.md) | The reusable error banner widget |
| [14_ui_profile_drawer.md](14_ui_profile_drawer.md) | The slide-out profile drawer (avatar, email, logout) |

### Flows — End-to-End Journeys
| File | What it covers |
|------|---------------|
| [11_full_flow.md](11_full_flow.md) | Complete walkthrough: app open → home screen |
