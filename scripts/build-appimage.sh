#!/usr/bin/env bash
# Build the Xournal++ Mobile AppImage.
#
# The Linux desktop toolchain (clang, GTK development files, appimage-builder)
# runs in a Docker container, so the build does not depend on host packages.
# The repository is mounted into the container, so all build outputs stay on
# the host.
#
# [1] The Docker image holds the Flutter SDK and every build tool
#     (docker/appimage-builder.Dockerfile). The image build is cached by
#     Docker layers, so later runs only redo the real build steps.
# [2] The host pub cache is mounted into the container when it exists, so
#     the container does not download the packages again.
# [3] The container runs with the UID and GID of the user that starts this
#     script. The files that the container writes stay under user control.
# [4] The version number comes from pubspec.yaml and reaches the recipe
#     (appimage_builder.yml) through the APP_VERSION environment variable.
# [5] The output is xournalpp-mobile-<version>-x86_64.AppImage in the
#     repository root. scripts/test-appimage.sh smoke tests the result.
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE_NAME="xournalpp-mobile-appimage-builder"
DOCKERFILE="docker/appimage-builder.Dockerfile"

# See note [1] in the docstring header: the container is the build
# requirement. Fail with install instructions when Docker is missing.
if ! command -v docker > /dev/null 2>&1; then
  echo "ERROR: docker is not installed or not in PATH." >&2
  echo "Install Docker from https://docs.docker.com/engine/install/ and retry." >&2
  exit 1
fi
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: the Docker daemon is not reachable. Start Docker and retry." >&2
  exit 1
fi

# See note [1] in the docstring header: the image holds the toolchain.
echo "==> Building the Docker image (cached after the first run)"
docker build -f "$DOCKERFILE" -t "$IMAGE_NAME" .

# See note [2] in the docstring header: reuse the host pub cache when it
# exists. The same path inside and outside the container keeps the package
# paths in .dart_tool/package_config.json valid for host commands too.
PUB_CACHE_ARGS=()
if [ -d "${HOME:-}/.pub-cache" ]; then
  PUB_CACHE_ARGS=(-v "${HOME}/.pub-cache:${HOME}/.pub-cache" -e "PUB_CACHE=${HOME}/.pub-cache")
fi

# See note [3] in the docstring header: match the host user, isolate HOME
# under /tmp because the container user cannot write to /home.
echo "==> Building the AppImage inside the container"
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp/builder \
  --volume "$PWD:/work" \
  --workdir /work \
  "${PUB_CACHE_ARGS[@]}" \
  "$IMAGE_NAME" \
  scripts/build-appimage-inner.sh

# See note [5] in the docstring header: report the artifact path.
APPIMAGE="$(ls -t xournalpp-mobile-*-x86_64.AppImage 2> /dev/null | head -n 1 || true)"
if [ -z "$APPIMAGE" ]; then
  echo "ERROR: no AppImage was produced." >&2
  exit 1
fi
echo "==> AppImage built: $PWD/$APPIMAGE"
echo "Next: scripts/test-appimage.sh '$APPIMAGE'"