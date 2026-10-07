#!/usr/bin/env bash
# Build the Xournal++ Mobile release APK, and optionally install it on a
# connected device (tablet sideload).
#
# The build is a fat APK (all ABIs in one file) so it installs on any tablet.
# Without key.properties the APK is signed with the auto-generated debug key,
# which is enough for local sideloading; CI and release flows stay unchanged.
#
# Usage: scripts/build-android-apk.sh [--split-per-abi] [--install]
#   --split-per-abi  pass the same flag to flutter build apk (one APK per ABI)
#   --install        run adb install -r on the produced APK (needs a device)
set -euo pipefail
cd "$(dirname "$0")/.."

FLUTTER_BIN="$(command -v flutter || true)"
if [ -z "$FLUTTER_BIN" ]; then
  # Common non-PATH location; adjust or export PATH if yours differs.
  for CANDIDATE in "$HOME/Installations/flutter-sdk/bin/flutter" /opt/flutter/bin/flutter; do
    if [ -x "$CANDIDATE" ]; then
      FLUTTER_BIN="$CANDIDATE"
      break
    fi
  done
fi
if [ -z "$FLUTTER_BIN" ]; then
  echo "ERROR: flutter not found in PATH. Install from https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

# Check the device before the build, so a missing device is reported first
# and the (long) build is not wasted when --install was requested.
ADB_BIN="$(command -v adb || true)"
if [ -z "$ADB_BIN" ] && [ -n "${ANDROID_HOME:-}" ] && [ -x "$ANDROID_HOME/platform-tools/adb" ]; then
  ADB_BIN="$ANDROID_HOME/platform-tools/adb"
fi

INSTALL=0
SPLIT=0
for ARG in "$@"; do
  case "$ARG" in
    --split-per-abi) SPLIT=1 ;;
    --install) INSTALL=1 ;;
    *)
      echo "Usage: scripts/build-android-apk.sh [--split-per-abi] [--install]" >&2
      exit 2
      ;;
  esac
done

if [ "$INSTALL" -eq 1 ]; then
  if [ -z "$ADB_BIN" ]; then
    echo "ERROR: adb not found for --install. Install platform-tools (sudo apt install adb)." >&2
    exit 1
  fi
  if ! "$ADB_BIN" get-state > /dev/null 2>&1; then
    echo "ERROR: no device attached. Enable USB debugging, connect the tablet and accept the prompt." >&2
    echo "Devices seen by adb:" >&2
    "$ADB_BIN" devices >&2
    exit 1
  fi
fi

echo "==> Building the release APK (fat APK, signed with the debug key without key.properties)"
if [ "$SPLIT" -eq 1 ]; then
  "$FLUTTER_BIN" build apk --release --split-per-abi
else
  "$FLUTTER_BIN" build apk --release
fi

APK_DIR="build/app/outputs/flutter-apk"
if [ "$SPLIT" -eq 1 ]; then
  APK="$APK_DIR/app-arm64-v8a-release.apk"
else
  APK="$APK_DIR/app-release.apk"
fi
if [ ! -f "$APK" ]; then
  echo "ERROR: expected APK not found: $APK" >&2
  ls -la "$APK_DIR" >&2 || true
  exit 1
fi

echo "==> APK built: $PWD/$APK"
if [ "$INSTALL" -eq 1 ]; then
  echo "==> Installing on the connected device"
  "$ADB_BIN" install -r "$APK"
  echo "==> Installed. Launch the app from the tablet app list."
fi