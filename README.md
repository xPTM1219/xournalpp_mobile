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
  - [Open web app](https://xournal.online/)
  - [Access via TOR](http://xournaltdtf7ygqxg3qik4tdg476smkukogil74t6oxqiwdnumy53hqd.onion/)
- Android
  - [Download in Google Play](https://play.google.com/store/apps/details?id=online.xournal.mobile)
  - [Download APK](https://github.com/xPTM1219/xournalpp_mobile/releases)
- Windows
  - [Build for Windows](https://github.com/xPTM1219/xournalpp_mobile/releases)
- Linux
  - [Download for Debian](https://github.com/xPTM1219/xournalpp_mobile/releases)
  - [Download for generic Linux](https://github.com/xPTM1219/xournalpp_mobile/releases)

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

## Known issues

- **Immense memory consumption**: *If you open immense files, you get immense memory consumption. That's logic. Usually, Xournal++ Mobile takes twice the file size plus around 50MB for itself.*
- But **why** does it take twice the memory?: *No idea. ¯\\\_(ツ)_/¯*

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

### Desktop support

Linux is perfectly supported by Xournal++ Mobile and you can get prebuilt binaries [above](#try-it-out).

Windows is supported and tested too. If you would like to build it yourself, execute the following commands.

```shell
flutter config --enable-linux-desktop # or --enable-macos-desktop or --enable-windows-desktop
flutter run -d linux # or macos or windows
```

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

Continuous integration runs on GitHub Actions (`.github/workflows/ci.yml`): analyze + test, Linux bundle, web build and release APK on every push to `main`. Pushing a `v*` tag builds release artifacts (APK, deb) and attaches them to a GitHub release via `.github/workflows/release.yml`.

No repository secrets are required. APK signing falls back to the debug key when `key.properties` is absent.
