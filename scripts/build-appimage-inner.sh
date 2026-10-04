#!/usr/bin/env bash
# Build the Xournal++ Mobile Linux bundle and package it as an AppImage.
#
# This script runs INSIDE the appimage-builder Docker container (see
# scripts/build-appimage.sh). A host with the full toolchain can also run it
# directly.
#
# [1] APP_VERSION feeds the recipe (appimage_builder.yml), which uses it in
#     the AppImage file name and in the desktop entry. The version comes
#     from pubspec.yaml.
# [2] The recipe is called with --skip-tests because the appimage-builder
#     test stage needs Docker inside the container. scripts/test-appimage.sh
#     does the smoke test of the finished AppImage instead.
set -euo pipefail
cd "$(dirname "$0")/.."

# See note [1] in the docstring header: version from pubspec.yaml.
APP_VERSION="$(grep '^version:' pubspec.yaml | awk '{ print $2 }' | cut -f1 -d '+')"
export APP_VERSION
echo "==> Building version ${APP_VERSION}"

mkdir -p "$HOME"

flutter config --enable-linux-desktop
flutter pub get
flutter build linux --release

# See note [2] in the docstring header.
appimage-builder --recipe appimage_builder.yml --skip-tests

ls -l xournalpp-mobile-*-x86_64.AppImage