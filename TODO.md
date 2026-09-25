# TODO

Deferred work recorded during phase 1 (toolchain modernization). The items
here are known breakages or follow-ups that later phases will pick up.

## Toolchain (phase 1 deferred items)

- [ ] `file_picker_cross` is vendored at `third_party/file_picker_cross`
      (fork of 4.6.0). Upstream is unmaintained (2022, Dart 2 era) and used the
      removed `NullThrownError`; the fork patches the 3 throw sites and bumps
      the SDK bound. Plan for phase 3: keep `FilePickerCross` for the recent
      files list and internal paths, replace the flaky open/save path with
      `file_picker` + `path_provider` + `share_plus`, then shrink or retire
      the vendored copy. Also drop the `file_picker`/`package_info_plus`/
      `win32`/`file` dependency overrides once the vendored copy is gone.
- [ ] `katex_flutter` was removed (unresolvable on Dart 3). The single LaTeX
      call site in `lib/layer_contents/XppTexImage.dart` now renders with
      `flutter_math_fork`. Review whether upstream KaTeX parity is needed
      (some TeX constructs differ between the two renderers).
- [ ] `receive_sharing_intent` 1.8.1 dropped the text-sharing API
      (`getTextStream`/`getInitialText`); those listeners were removed from
      `lib/pages/OpenPage.dart`. When Flutter 3.38+ is adopted, upgrade to
      1.9.0 and re-evaluate text intent handling. The media stream is now
      only wired on non-web platforms (the plugin has no web implementation).
- [ ] `flutter_absolute_path` and `matrix_gesture_detector` were unused and
      removed. Verify no dynamic use remains (none found in `lib/`).
- [ ] Android release signing: `app/build.gradle.kts` signs release builds
      with the debug key. Phase 6 adds the `key.properties` based setup and
      documents the Android SDK + JDK 17 installation for local builds.
- [ ] Local Android builds are not possible on this machine yet: no Android
      SDK is installed (`flutter doctor` reports the toolchain missing). The
      Gradle 8.12 + AGP 8.9.1 + Kotlin 2.1.0 configuration is validated up to
      SDK resolution (`gradlew help` configures cleanly, then fails with
      "SDK location not found"). Phase 6 / CI covers the real APK build.
- [ ] Linux desktop build needs clang++, cmake, ninja and GTK 3 dev packages
      (`libgtk-3-dev`), and the `linux/` scaffold still needs regeneration
      when a phase builds Linux targets.
- [ ] The `S` field in `ToolSettingDialog` is typed `Object?` and unused;
      clean it up together with the surrounding dialog code.
- [ ] `flutter analyze` reports ~270 style-level infos (file naming,
      `withOpacity`, string interpolation, build context across async gaps).
      Clean these up opportunistically; none block a build.
- [ ] The web icon set has `Icon-1024.png` but not the maskable icons that
      the current template ships; consider adding maskable icons with the
      GitHub Pages work (phase 7).

## Runtime fixes validated in phase 1

- `CanvasPage.loadToolSettings` no longer force-unwraps missing
  `toolColor`/`toolWidth` preferences; first launch now keeps the defaults
  instead of throwing on every canvas open.
- `EditingToolBar` guards `Platform.isAndroid`/`Platform.isIOS` with `kIsWeb`;
  the unguarded `dart:io` access crashed every `build()` on web, which made
  the editing toolbar invisible and killed the canvas page.
- `DropFile` uses `onDropFile` instead of the deprecated `onDrop`; the old
  callback received a raw `web.File` that failed the internal
  `DropzoneFileInterface` cast, so dropped XOPP files never opened.
- `XppLayerStack` builds a typed `List<Widget>`; the previous
  `List<Widget?> ... as List<Widget>` cast threw on web whenever a page
  rendered content (strokes, text), leaving the canvas blank.

## Existing backlog (from issue 10 triage, phase 8)

- [ ] Recorded after phase 8 triage.