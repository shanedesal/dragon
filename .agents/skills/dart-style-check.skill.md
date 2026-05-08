---
description: "Check Dart/Flutter code changes for formatting, naming, and spacing using flutter_lints and analyzer. Use when reviewing Dart diffs or validating style before merging."
argument-hint: "Use --all to scan everything, otherwise checks changed files only"
---

# Dart Style Check

## When to Use
- Validate Dart or Flutter changes for formatting and naming consistency
- Pre-PR or pre-merge style check for this repo

## Procedure

1. **Decide the scope to check.**
   - Default: check only changed files.
   - If the user adds `--all`, scan all Dart files under `lib/` and `test/`.

2. **Identify Dart files in scope.**
   - For changed files, prefer `git diff` with a `.dart` filter.
   - Exclude generated files: `*.g.dart`, `*.freezed.dart`, and `*.gen.dart`.

3. **Run the formatter** to enforce spacing and line breaks.
   - Use `dart format --set-exit-if-changed <paths>`.

4. **Run the analyzer** to enforce `flutter_lints` rules.
   - Use `flutter analyze` (uses `flutter_lints` via `analysis_options.yaml`).
   - If Flutter tooling is unavailable, use `dart analyze` but keep focus on `flutter_lints`.
   - Report only errors (ignore warnings and infos).

5. **Review any remaining naming or readability issues** that are not covered by `flutter_lints`.

## Decision Points
- If formatting changes files, keep the formatted output and re-run the analyzer.
- If analyzer warns on naming, align with existing code patterns unless the lint rules say otherwise.

## Completion Checklist
- Formatter reports no remaining changes.
- Analyzer completes with no errors.
- Naming and spacing are consistent with existing Dart code in this repo.

## Example Prompts
- Run dart-style-check for current changes
- Run dart-style-check --all to scan everything
