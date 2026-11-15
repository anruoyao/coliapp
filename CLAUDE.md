# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## Project

Chatter (package id `com.mishe.chatter`, internal code prefix "Colibri") is a Flutter social app client for the misskey.site Laravel backend, whose repo lives separately in `../coli`. The Flutter project is the `chatter/` subdirectory (`chatter_flutter/chatter`); stack: GetX (`get`) for state/routing, GetStorage for local caching, `intl`, `webview_flutter`, `video_player`/`video_compress`.

This directory is **not** a git repository — there is no git baseline for diffs or rollback.

## Common Commands

Run all Flutter commands from the `chatter/` subdirectory (running them from the parent finds sources but not `test/`):

```bash
cd chatter

# Static analysis (baseline: no errors, but pre-existing style lints remain)
flutter analyze
flutter analyze lib/screens/colibri_feed/colibri_feed_screen.dart

# Tests (use --no-pub; a single file targets just your change)
flutter test --no-pub
flutter test --no-pub test/colibri_toast_test.dart

# Release APK -> build/app/outputs/flutter-apk/app-release.apk (~113 MB)
flutter build apk

# Format ONLY the files you touched — never the whole repo
dart format --set-exit-if-changed lib/path/to/file.dart
```

`test/widget_test.dart` is the stale counter scaffold; it fails because the live page has no "0" text. Treat it as a known failure unrelated to your change.

## Architecture

- `lib/screens/colibri_feed/` holds the timeline (feed screen, post card, story bar/viewer, post detail). The shared `ColibriPostCard` renders posts on every surface (home, profile, detail, favorites, search) — change it once, then verify all surfaces.
- `lib/common/api_service/` holds API services (e.g. `colibri_timeline_service.dart`). `lib/common/managers/` has `SessionManager` (reactive current-user cache) and `version_check_manager.dart`. GetX controllers extend `lib/common/controller/base_controller.dart`.
- UI strings: `lib/localization/languages/<lang>.dart` keyed via `LKeys`. There are 22+ language files — every new string must be added to all of them, and a duplicated key across language files breaks the build.
- Versioning: `android/app/build.gradle` hardcodes the release `versionName`/`versionCode` and is the source of truth for release builds; keep `pubspec.yaml` in sync (bump both, e.g. 1.34/28 → 1.35/29). APK signing is stable, so new builds overlay-install over old ones.

## Lessons Learned / Pitfalls

- Toasts: all transient feedback uses the bottom-center capsule widget `lib/common/widgets/colibri_bookmark_toast.dart` (success/failure/info states, long-text wrapping). The codebase was migrated off 88 `Get.snackbar` + 5 `ScaffoldMessenger` call sites — do not reintroduce them.
- Translation: posts are translated via `POST /api/translator/translate` with `{post_id, target}`; the server caches translations permanently. Never send post content from the client. Map unsupported locales to English.
- Async UI hygiene (translation, avatar refresh): discard stale responses on post/content/locale change and on disposal, block duplicate clicks while loading, and keep `SessionManager`-cached user data reactive so avatar updates propagate. Guarded bootstrap refreshes must not repopulate data after logout or account switch.
- Feed separators: use a 1px `Divider` colored `cLightBg`; the user explicitly rejected 8px gray separator bands as ugly.
- API contract example: the backend sends `is_ad` on shadow/ad posts; `ColibriPost` parses and preserves it and the card shows an "Ad" badge next to the author. When adding a field, extend the model with parsing + `copyWith`.
- Without git, verify changes via targeted `flutter analyze` on touched files, targeted tests, and grep for residual old APIs. Never run a full-repo `dart format` — an accidental 206-file reformat buried the real diff and could not be reverted.
- Deploying the backend (`../coli` → pull on server as the `www` user) does NOT deploy any Flutter change; Flutter ships only through APK builds.
