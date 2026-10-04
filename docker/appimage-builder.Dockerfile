# Build environment for the Xournal++ Mobile AppImage.
#
# Ubuntu 22.04 (jammy) is used on purpose:
# [1] appimage-builder 1.1.0 calls apt-key, which Ubuntu removed in 24.04.
# [2] The Flutter toolchain builds against glibc 2.35 here. The Debian
#     bookworm (glibc 2.36) runtime that the recipe bundles through
#     appimage-builder is newer, so the AppImage also runs on old hosts.
# [3] The Flutter SDK version is pinned to the one used in CI
#     (.github/workflows/ci.yml).
FROM ubuntu:22.04

ARG FLUTTER_VERSION=3.47.5
ENV DEBIAN_FRONTEND=noninteractive

# Flutter Linux desktop build dependencies plus the host tools that
# appimage-builder calls:
# - binutils (readelf), squashfs-tools (mksquashfs), fakeroot, patchelf
# - libglib2.0-bin (glib-compile-schemas), shared-mime-info
#   (update-mime-database), libgtk-3-0 (gtk-update-icon-cache)
# - gdk-pixbuf-query-loaders comes with libgtk-3-dev
# - xvfb for the smoke test in scripts/test-appimage.sh
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
      binutils \
      ca-certificates \
      clang \
      cmake \
      coreutils \
      curl \
      desktop-file-utils \
      fakeroot \
      fuse \
      git \
      libglib2.0-bin \
      libgtk-3-dev \
      liblzma-dev \
      ninja-build \
      patchelf \
      pkg-config \
      python3-pip \
      python3-setuptools \
      shared-mime-info \
      squashfs-tools \
      strace \
      unzip \
      util-linux \
      xvfb \
      xz-utils \
    && rm -rf /var/lib/apt/lists/*

# appimage-builder bundles the AppImageKit runtime itself, so appimagetool
# is not needed. lief stays below 1.0: the APIs that the 1.1.0 recipe code
# calls changed in the 1.0 release.
RUN pip3 install --no-cache-dir appimage-builder==1.1.0 "lief<1.0"

# See note [3] in the header: pinned Flutter SDK. Install, warm the caches
# and clean up in a single layer:
# - flutter needs its .git checkout, so the tarball stays a git checkout
# - precache --linux also fetches the Android engines and the web SDK,
#   which this image never uses
# - the container runs as the host user, which needs write access to the
#   SDK cache for lock files and snapshots
# - git refuses the checkout until the directory is marked safe
RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --system --add safe.directory /opt/flutter \
    && /opt/flutter/bin/flutter config --enable-linux-desktop \
    && /opt/flutter/bin/flutter precache --linux \
    && /opt/flutter/bin/flutter --version \
    && find /opt/flutter/bin/cache/artifacts/engine -mindepth 1 -maxdepth 1 \
         ! -name "linux-x64*" -exec rm -rf {} + \
    && rm -rf /opt/flutter/bin/cache/flutter_web_sdk \
    && chmod -R a+rwX /opt/flutter

ENV PATH="/opt/flutter/bin:${PATH}"

WORKDIR /work

CMD ["bash"]