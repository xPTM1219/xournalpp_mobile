# TODO

Deferred work for Xournal++ Mobile. Every item carries a one-line context and
the files it touches; finished work moves out of this list.

## Save/Open

- [ ] Full `file_picker_cross` removal. Phase 3 moved only the flaky save and
      open paths to `file_picker` + `path_provider`
      (`lib/src/file_service.dart`). Remaining call sites:
  - Recent files list: `OpenPage.dart` still uses
    `FilePickerCross.fromInternalPath` for taps and
    `FilePickerCross.delete` for removal; those paths only reach the
    internal fake filesystem written by the vendored package.
  - Background lookups: `XppBackground.dart` resolves pixmap/pdf backgrounds
    through `FilePickerCross.fromInternalPath` (including the pdf import
    path in `XppFile.importPdf`).
  - Share-intent open path: `OpenPage.receivedShareNotification` decodes via
    `openFileByUri` (`lib/src/conditional/open_file/*.dart`), which wraps
    bytes in `FilePickerCross`.
  - Remaining pickers: web branch of `FileService.pickXopp`
    (`lib/src/file_service.dart`), image insert dialog
    (`lib/layer_contents/XppImage.dart`), Import PDF dialog
    (`lib/pages/OpenPage.dart`), quota tile (`lib/widgets/QuotaTile.dart`).
  - Web download leftovers: `CanvasPage.shareScreenshot` and the web branch
    of `FileService.exportXoppAs` still use
    `FilePickerCross.exportToStorage`; the browser save/open already moved
    to IndexedDB in phase 7.
  - `XppFile.toFilePickerCross` helper is now unused; delete it during the
    removal.
- [ ] After removal, drop the vendored copy at
      `third_party/file_picker_cross` (plus the vendored `disk_space` fork if
      nothing else needs it) and the `file_picker`, `package_info_plus`,
      `win32`, `file`, and `share_plus` `dependency_overrides` from
      `pubspec.yaml`.
- [ ] Streaming XML parse + lazy page loading for constant-memory open of
      huge `.xopp` files. The parser in `XppFile.fromFilePickerCross` still
      buffers the whole decompressed XML text and the full document tree;
      a streaming parse (`XmlEventIterator`) with on-demand page loading
      would make open memory constant per page.
- [ ] Share-intent optimization: do not copy files we can read directly.
      `receivedShareNotification` in `lib/pages/OpenPage.dart` copies every
      shared file into the app directory before parsing.

## Rendering

- [ ] Layer management UI: multi-layer draw/select/reorder. New content is
      always appended to layer 0 (`/// TODO: manage layers` in
      `lib/pages/CanvasPage.dart`).
- [ ] Pixmap page backgrounds on web. The pixmap background lookup is
      desktop/mobile only (`/// TODO: implement background for web` in
      `lib/src/XppBackground.dart`).
- [ ] Teximage bottom/right corners and LaTeX text-size handling. The box is
      derived from the render, not stored; freshly created elements keep
      (0, 0) until a render pass measures it (`lib/layer_contents/XppTexImage.dart`).
- [ ] Selection tools. The `inRegion`/`shouldSelectAt` helpers are
      implemented and tested (`lib/layer_contents/*.dart`); a select tool
      that uses them is still missing.
- [ ] LaTeX renderer parity review. `katex_flutter` was removed (unresolvable
      on Dart 3); the call site renders with `flutter_math_fork`
      (`lib/layer_contents/XppTexImage.dart`). Some TeX constructs differ
      between the two renderers.

## Platforms

- [ ] Custom language switcher setting. The app auto-loads en/de/pt from the
      platform locale; a user override is not implemented
      (`/// TODO: implement custom change of language` in
      `lib/pages/OpenPage.dart`).
- [ ] `receive_sharing_intent` 1.9 upgrade when Flutter 3.38+ is adopted;
      1.8.1 dropped the text-sharing API (`getTextStream`/`getInitialText`),
      re-evaluate text intent handling then (`lib/pages/OpenPage.dart`).
- [ ] Web maskable icons. The icon set has `Icon-1024.png` but not the
      maskable icons the current template ships (`web/`).

## Build/Release

- [ ] Android release signing setup. Release APKs are currently signed with
      the debug key when `key.properties` is absent
      (`android/app/build.gradle.kts` already reads `key.properties` and
      picks the `release` config when present). Steps needed:
  - [ ] Generate an upload keystore:
        `keytool -genkey -v -keystore ~/xournal-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
        Back the file up; losing it means a new app identity on stores.
  - [ ] Create `android/key.properties` (gitignored) from this template:
        `storeFile=/absolute/path/to/xournal-upload.jks`,
        `storePassword=...`, `keyAlias=upload`, `keyPassword=...`.
  - [ ] Add the GitHub secrets `KEY_BASE64` (base64 of the keystore),
        `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`; CI decodes the
        keystore, writes `key.properties`, and signs the release APK
        properly (keep the debug-key fallback for unsigned local builds).
  - [ ] Play Store listing consideration: an AAB (`flutter build appbundle`)
        is required for new Play listings; decide whether to publish an AAB
        next to the APK in releases.
- [ ] AppImage build pipeline improvements:
  - [ ] The appimage-builder distro matrix tests stay disabled
        (`--skip-tests` needs Docker-in-Docker); `scripts/test-appimage.sh`
        does a 15s launch smoke test instead.
  - [ ] The Docker image is rebuilt on every CI run because the runner has
        no layer cache; cache it in GHCR or with `actions/cache`.
  - [ ] Only x86_64 is built; an aarch64 AppImage needs arm64 Flutter
        artifacts, an arm64 `apt.arch`, and an arm64 build host.
  - [ ] The AppImage relies on the host X11/Wayland client libraries; add
        `libx11-6` and the xcb/wayland packages to the recipe `apt.include`
        list if a target host lacks them.
- [ ] Local Android builds need the full Android SDK + JDK 17 on the dev
      machine (`flutter doctor` reports the toolchain missing); CI always
      produces APK artifacts (`scripts/check-android-env.sh` prints the
      missing steps).
- [ ] Linux desktop build needs clang++, cmake, ninja and GTK 3 dev packages,
      and the `linux/` scaffold still needs regeneration when a phase builds
      Linux targets.
- [ ] Style-level analyzer infos (~300: file naming, `withOpacity`,
      build context across async gaps). `flutter_lints` is enabled; clean
      these up opportunistically, none block a build.
- [ ] The `S` field in `ToolSettingDialog` is typed `Object?` and unused;
      clean it up together with the surrounding dialog code
      (`lib/widgets/ToolSettingDialog.dart`).