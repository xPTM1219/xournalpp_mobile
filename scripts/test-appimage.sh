#!/usr/bin/env bash
# Smoke test for the Xournal++ Mobile AppImage.
#
# The test starts the AppImage on a virtual display and checks that the
# process stays alive. A full interactive test stays a manual task; the
# script prints the manual instructions at the end.
#
# [1] --appimage-extract-and-run avoids FUSE: the AppImage unpacks itself
#     to a temporary directory and starts from there.
# [2] The test runs inside the appimage-builder Docker container when
#     Docker is available. That container holds xvfb, so the test needs no
#     host packages. Without Docker the test runs on the host.
# [3] The process must stay alive for the full wait time. The app is a GUI
#     application, so an early exit means a startup crash.
# [4] xvfb provides the X display for the headless run.
set -euo pipefail
cd "$(dirname "$0")/.."

# See note [2] in the docstring header: rerun this script inside the
# container, which holds xvfb and the same build environment.
if [ "${TEST_APPIMAGE_INNER:-0}" != "1" ] && command -v docker > /dev/null 2>&1; then
  IMAGE_NAME="xournalpp-mobile-appimage-builder"
  if docker info > /dev/null 2>&1 && docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "==> Running the smoke test inside the Docker container"
    exec docker run --rm \
      -e TEST_APPIMAGE_INNER=1 \
      -v "$PWD:/work" \
      -w /work \
      "$IMAGE_NAME" \
      scripts/test-appimage.sh
  fi
fi

# See notes [1] and [2] in the docstring header: pick the newest AppImage in
# the repository root, or the file given as the first argument.
APPIMAGE="${1:-}"
if [ -z "$APPIMAGE" ]; then
  APPIMAGE="$(ls -t xournalpp-mobile-*-x86_64.AppImage 2> /dev/null | head -n 1 || true)"
fi
if [ -z "$APPIMAGE" ] || [ ! -f "$APPIMAGE" ]; then
  echo "ERROR: no AppImage found. Run scripts/build-appimage.sh first." >&2
  exit 1
fi
chmod +x "$APPIMAGE"

# See note [3] in the docstring header: the wait time is configurable.
WAIT_SECONDS="${WAIT_SECONDS:-15}"

# See note [4] in the docstring header: virtual display with an isolated
# home, so the test does not touch the session.
export HOME="$(mktemp -d)"
mkdir -p "$HOME/xdg"
export XDG_RUNTIME_DIR="$HOME/xdg"
LOG="$(mktemp)"

# xvfb-run when available; otherwise run on the session display.
if command -v xvfb-run > /dev/null 2>&1; then
  RUNNER=(xvfb-run -a)
elif [ -n "${DISPLAY:-}" ]; then
  RUNNER=(env)
else
  echo "ERROR: no display and no xvfb-run. Install xvfb (apt install xvfb)" >&2
  exit 1
fi

echo "==> Starting $APPIMAGE (waiting ${WAIT_SECONDS}s)"
# See notes [1] and [3] in the docstring header: extract and run, then
# check that the process survived the wait.
"${RUNNER[@]}" "./$APPIMAGE" --appimage-extract-and-run > "$LOG" 2>&1 &
PID=$!

sleep "$WAIT_SECONDS"
if ! kill -0 "$PID" 2> /dev/null; then
  echo "ERROR: the AppImage process exited early. Output:" >&2
  cat "$LOG" >&2
  exit 1
fi

kill "$PID" 2> /dev/null || true
wait "$PID" 2> /dev/null || true
echo "==> OK: the process stayed alive for ${WAIT_SECONDS}s"

cat <<EOF

Manual test: run the AppImage on your desktop and open a notebook.

  chmod +x $APPIMAGE
  ./$APPIMAGE

EOF