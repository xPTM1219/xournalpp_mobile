# <img src="assets/xournalpp-adaptive.png" width="64" style="height: auto;"/> Xournal++ Mobile

***Warning:*** *Xournal++ Mobile is currently in early development and **not** yet stable. Use with caution!*

[![Current version](https://img.shields.io/badge/dynamic/yaml?label=Current%20version&query=version&url=https%3A%2F%2Fraw.githubusercontent.com%2FxPTM1219%2Fxournalpp_mobile%2Fmain%2Fpubspec.yaml%3Finline%3Dfalse&style=for-the-badge&logo=flutter&logoColor=white)](https://github.com/xPTM1219/xournalpp_mobile/releases) [![CI](https://img.shields.io/github/actions/workflow/status/xPTM1219/xournalpp_mobile/ci.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/xPTM1219/xournalpp_mobile/actions/workflows/ci.yml)

A port of the main features of Xournal++ to various Flutter platforms like Android, iOS and the Web.

![Feature banner](assets/feature-banner.svg)

## Updated repo

This repo picks up the work from the possible abandoned repo in Gitlab and now
archived Github repo with the objective of updating it and fixing existing
issues. I have no plans for the moment of testing the iOS app since I don't own
any Apple device. I will be testing in Linux, Android, Web and Windows.
Of course, any help is welcome.

## Try it out

***Mission completed:** We can now render strokes, images and text and LaTeX!. We thereby support the full `.xopp` file format.* :tada:

- Web
  - [Open web app](https://xptm1219.github.io/xournalpp_mobile/)

  On the web, **Save** stores the notebook in your browser's storage
  (IndexedDB), so it is still there after a reload. **Save as...** downloads
  the `.xopp` file to your device. You can reopen a notebook by dropping the
  file onto the open page or by using the file picker button.
- Android
  - [Download in Google Play](https://play.google.com/store/apps/details?id=online.xournal.mobile)
  - [Download APK](https://github.com/xPTM1219/xournalpp_mobile/releases)
- Windows
  - [Build for Windows](https://github.com/xPTM1219/xournalpp_mobile/releases)
- Linux
  - [Download AppImage](https://github.com/xPTM1219/xournalpp_mobile/releases) (any distribution)

### Visible parts already working

- [x] Read the document title
- [x] Read and display the number of pages
- [x] Create thumbnails of the pages for the navigation bar
- [x] Smooth fade in after thumbnail rendering
- [x] Render images on the canvas
- [x] Render text on the canvas
- [x] Strokes
- [x] Highlighter
- [x] LaTeX
- [x] Recent files list
- [ ] Whiteout eraser
- [x] Saving
- [x] Basic editing
- [x] Basic PDF rendering

## Requirements

### Linux

- Debian based `apt install cmake ninja-build clang libgtk-3-dev`
- AppImage packaging: [Docker](https://docs.docker.com/engine/install/), the
  rest of the toolchain lives in the build container

## Known issues

- **Memory on huge files**: *Memory use stays proportional to the pages you
  view, not the total page count: PDF pages are rasterized one page at a
  time and kept in a small LRU cache (~8 pages) instead of rasterizing the
  whole document per page. Opening immense files still buffers the full
  document in memory; a streaming parser with lazy page loading would fix
  that — see [TODO.md](TODO.md).*
- **Wayland**: *The AppImage starts through XWayland: the recipe sets
  `GDK_BACKEND=x11` (the old snap needed `DISABLE_WAYLAND=1` for the same
  problem). If you want to try native Wayland, start it with
  `GDK_BACKEND=wayland`.*

## Getting started

### Prepare

> You would like to contribute? Please check out issues to solve [here](https://github.com/xPTM1219/xournalpp_mobile/issues) or get our `// TODO:`s [here](https://github.com/xPTM1219/xournalpp_mobile/blob/main/TODO.md)!

Get your information about the `.xopp` file format at http://www-math.mit.edu/~auroux/software/xournal/manual.html#file-format .

Install Flutter first. See [flutter.dev](https://flutter.dev/docs/get-started/install) for more details.

```shell
# Run Flutter doctor to check whether the installation was successful
flutter doctor
```

### Get the sources and run

Connect any Android or iOS device.

```shell
git clone https://github.com/xPTM1219/xournalpp_mobile.git
cd xournalpp_mobile
flutter run
```

### Test for the web

If you want to test for the web, please run:

```shell
flutter config --enable-web
flutter run -d web --release # unfortunately, the debug flavour will result an empty screen
```

To test the GitHub Pages subpath layout locally:

```shell
flutter build web --release --base-href /xournalpp_mobile/
# serve build/web under that prefix, e.g.:
#   cd build/web && python3 -m http.server 8080
# then open http://localhost:8080/xournalpp_mobile/
```

### Web deployment (GitHub Pages)

The web app auto-deploys to
<https://xptm1219.github.io/xournalpp_mobile/> whenever a `v*` tag is pushed
(see `.github/workflows/pages.yml`; GitHub Pages is enabled by the workflow
itself). To deploy, push a tag: `git tag v1.2.0 && git push origin v1.2.0`.

The workflow can also be triggered manually from the **Actions** tab
(*Deploy to GitHub Pages* → *Run workflow*).

### Desktop support

Linux is perfectly supported by Xournal++ Mobile and you can get prebuilt binaries [above](#try-it-out).

Windows is supported and tested too. If you would like to build it yourself, execute the following commands.

```shell
flutter config --enable-linux-desktop # or --enable-macos-desktop or --enable-windows-desktop
flutter run -d linux # or macos or windows
```

### Build the AppImage

The AppImage build runs in a Docker container, so no Linux build toolchain is
needed on the host. The container holds a pinned Flutter SDK and
[appimage-builder](https://appimage-builder.readthedocs.io).

```shell
scripts/build-appimage.sh   # builds xournalpp-mobile-<version>-x86_64.AppImage
scripts/test-appimage.sh    # smoke test: launches the AppImage on a virtual display
```

Downloaded AppImages run the same way:

```shell
chmod +x xournalpp-mobile-*-x86_64.AppImage
./xournalpp-mobile-*-x86_64.AppImage
```

### Android

The release APK is built with the debug key when `key.properties` is absent,
so no signing setup is needed for local and CI builds. A full release signing
setup is tracked in [TODO.md](TODO.md).

Prerequisites: JDK 17, the full Android SDK (cmdline-tools,
`platforms;android-35`, `build-tools`) and adb. Check what is missing on your
machine:

```shell
scripts/check-android-env.sh
```

The script prints the exact `sdkmanager` install steps for each missing part.
A bare platform-tools install (adb only) is not enough to build.

Build the release APK (a fat APK that installs on any tablet):

```shell
scripts/build-android-apk.sh                   # build/app/outputs/flutter-apk/app-release.apk
scripts/build-android-apk.sh --split-per-abi   # one APK per ABI instead
scripts/build-android-apk.sh --install         # also adb install -r on a connected device
```

Manual commands, if you prefer:

```shell
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

#### Tablet sideload

1. On the tablet, enable **Developer options** (tap *Build number* seven times
   in *Settings › About tablet*) and inside it **USB debugging**.
2. Connect by USB and accept the debugging prompt on the tablet
   (`adb devices` must list it), then:

   ```shell
   scripts/build-android-apk.sh --install
   ```

3. Without a USB cable: copy the APK to the tablet (download from the
   [releases](https://github.com/xPTM1219/xournalpp_mobile/releases) page or
   `adb push <apk> /sdcard/Download/`), then open it from a file manager. You
   must allow **Install unknown apps** for that file manager once; after the
   warning, confirm the install.

The same steps install the APK artifact from CI or a release download.

## Colors and Typography

### Colors

Our primary color is the Material DeepPurple. I simply prefer a colorful application over an old-fashioned gray GTK+ application.

`#673ab7` / `rgb(103, 58, 183)` / `CMYK(44%, 68%, 0%, 28%)` / `hsl(261°, 51%, 48%)`

The accent color is Material Pink.

`#e91e63` / `rgb(233, 30, 99)` / `CMYK(0%, 87%, 58%, 9%)`/ `hsl(340°, 81%, 51%)`

The light color is White.

`#ffffff` / `rgb(255, 255, 255)` / `CMYK(0%, 0%, 0%, 0%)`/ `hsl(0°, 0%, 100%)`

The dark color is Material Blue Grey 900.

`#263238` / `rgb(38, 50, 56)` / `CMYK(32%, 11%, 0%, 78%)`/ `hsl(200°, 19%, 18%)`

### Fonts

- Display Text: Open Sans Extra Bold *(800)* `Apache 2.0`, *accent color* or *light color*
- Title and Heading: Open Sans Regular *(400)* `Apache 2.0`, *light color*
- Emphasis: Glacial Indifference Regular *(400)* `SIL Open Font License`, *light color*, *UPPERCASE*
- Body: Open Sans Light *(300)* `Apache 2.0`, *light color*

## Misc

To be updated: ~~*Like this project? [Buy me a Coffee](https://buymeacoff.ee/braid).*~~

~~This software is powered by the education software [TestApp](https://testapp.schule) — **Learning. Easily.**~~

## Legal notes

This project is licensed under the terms and conditions of the EUPL-1.2 found in [LICENSE](LICENSE).

## Resources

* [Original project in Gitlab](https://gitlab.com/TheOneWithTheBraid/xournalpp_mobile)

## CI

Continuous integration runs on GitHub Actions (`.github/workflows/ci.yml`): analyze + test, Linux bundle, web build, release APK (artifact `xournalpp-mobile-<version>.apk`) and the AppImage (Docker build with a launch smoke test) on every push to `main`. Pushing a `v*` tag builds release artifacts (APK, AppImage) and attaches them to a GitHub release via `.github/workflows/release.yml`.

No repository secrets are required. APK signing falls back to the debug key when `key.properties` is absent.
