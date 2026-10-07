#!/usr/bin/env bash
# Check the local Android build prerequisites for Xournal++ Mobile.
#
# The release APK build needs the Flutter SDK, a full Android SDK
# (cmdline-tools, platforms, build-tools) and JDK 17. Many machines only have
# the standalone platform-tools (adb); this script prints what is missing and
# the exact sdkmanager commands to install it. The build tool is Gradle (kept,
# because Maven cannot build Flutter apps); no extra Maven setup is needed.
#
# Exit code 0 when everything is present, 1 otherwise.
set -euo pipefail

MISSING=0

warn_missing() {
  MISSING=1
  echo "MISSING: $1"
}

echo "==> Flutter SDK"
FLUTTER_BIN="$(command -v flutter || true)"
if [ -z "$FLUTTER_BIN" ]; then
  # Common non-PATH location; adjust or export PATH if yours differs.
  for CANDIDATE in "$HOME/Installations/flutter-sdk/bin/flutter" /opt/flutter/bin/flutter; do
    if [ -x "$CANDIDATE" ]; then
      FLUTTER_BIN="$CANDIDATE"
      echo "Found flutter outside PATH: $FLUTTER_BIN"
      break
    fi
  done
fi
if [ -n "$FLUTTER_BIN" ]; then
  "$FLUTTER_BIN" --version | head -n 1
else
  warn_missing "flutter in PATH. Install from https://docs.flutter.dev/get-started/install and export its bin/ folder."
fi

echo
echo "==> Java (need 17 for AGP 8)"
if command -v java > /dev/null 2>&1; then
  JAVA_VERSION="$(java -version 2>&1 | head -n 1)"
  echo "$JAVA_VERSION"
  if ! java -version 2>&1 | head -n 1 | grep -qE 'version "(17|21)\.'; then
    warn_missing "JDK 17 (or 21). Example on Ubuntu/Debian: sudo apt install openjdk-17-jdk"
  fi
else
  warn_missing "java. Example on Ubuntu/Debian: sudo apt install openjdk-17-jdk"
fi

echo
echo "==> Android SDK"
SDK_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$SDK_HOME" ]; then
  # Default locations of Android Studio and the cmdline-tools install.
  for CANDIDATE in "$HOME/Android/Sdk" "/opt/android-sdk" "/usr/lib/android-sdk"; do
    if [ -d "$CANDIDATE" ]; then
      SDK_HOME="$CANDIDATE"
      echo "Found SDK without ANDROID_HOME: $SDK_HOME"
      break
    fi
  done
fi

if [ -n "$SDK_HOME" ] && [ -x "$SDK_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "SDK home: $SDK_HOME"

  SDKMANAGER="$SDK_HOME/cmdline-tools/latest/bin/sdkmanager"
  HAVE_PLATFORM="$(ls "$SDK_HOME/platforms" 2> /dev/null | grep -E '^android-(35|36)$' | sort -V | tail -n 1 || true)"
  if [ -n "$HAVE_PLATFORM" ]; then
    echo "Platform installed: $HAVE_PLATFORM"
  else
    warn_missing "platform android-35. Install with: yes | $SDKMANAGER \"platforms;android-35\""
  fi

  if ls "$SDK_HOME/build-tools" 2> /dev/null | grep -qE '^(3[0-9]|35)\.'; then
    echo "Build-tools installed: $(ls "$SDK_HOME/build-tools" | tail -n 1)"
  else
    warn_missing "build-tools. Install with: yes | $SDKMANAGER \"build-tools;35.0.0\""
  fi

  if [ -f "$SDK_HOME/licenses/android-sdk-license" ]; then
    echo "Licenses accepted."
  else
    warn_missing "SDK licenses. Accept with: yes | $SDKMANAGER --licenses"
  fi
else
  warn_missing "full Android SDK (a platform-tools only install is not enough)."
  cat <<'EOF'
Install steps (Ubuntu/Debian example):
  1. Download the command line tools:
     https://developer.android.com/studio#command-line-tools-only
  2. Unpack to a folder, then layout it as <sdk-home>/cmdline-tools/latest/:
     mkdir -p ~/Android/Sdk/cmdline-tools
     unzip commandlinetools-linux-*.zip -d ~/Android/Sdk/cmdline-tools
     mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
  3. Install the build components (JDK 17 required):
     yes | ~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --licenses
     yes | ~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager \
       "platform-tools" "platforms;android-35" "build-tools;35.0.0"
  4. Export the location in ~/.bashrc and retry this script:
     export ANDROID_HOME=~/Android/Sdk
EOF
fi

echo
echo "==> adb (only needed for --install and the tablet sideload)"
ADB_BIN="$(command -v adb || true)"
if [ -z "$ADB_BIN" ]; then
  # Standalone platform-tools install (no full SDK).
  for CANDIDATE in "$HOME/Installations/android-platform-tools" "$HOME/Android/Sdk/platform-tools"; do
    if [ -x "$CANDIDATE/adb" ]; then
      ADB_BIN="$CANDIDATE/adb"
      echo "adb found outside PATH: $ADB_BIN"
      break
    fi
  done
fi
if [ -n "$ADB_BIN" ]; then
  [ "$(basename "$ADB_BIN")" = "adb" ] && echo "adb found."
else
  warn_missing "adb. Install with: sudo apt install adb, or the platform-tools package of the SDK above."
fi

echo
echo "==> flutter doctor (Android toolchain)"
if [ -n "$FLUTTER_BIN" ]; then
  "$FLUTTER_BIN" doctor 2>&1 | grep -E '^\s*\[' || true
fi

echo
if [ "$MISSING" -eq 0 ]; then
  echo "RESULT: Android build environment is complete."
else
  echo "RESULT: parts of the Android build environment are missing (see MISSING lines above)."
  echo "CI always builds the APK; local builds only work after the install steps."
  exit 1
fi