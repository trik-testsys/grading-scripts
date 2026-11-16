#!/bin/bash
# Builds TRIK Studio from source at a pinned commit and assembles /TRIKStudio.
# Runs in the builder stage of docker/Dockerfile.
#
# Usage: ./build_trik.sh <trik studio version> <trik-studio commit sha>
#
# Result:
#   /TRIKStudio/bin                  - build output (2D-model, patcher, trik-studio, libraries, plugins)
#   /TRIKStudio/trik-studio          - link to bin/trik-studio (used by echo_version.sh)
#   /TRIKStudio/lib/python-runtime   - Python stdlib + numpy (TRIK_PYTHONPATH in grade.sh)
#   /runtime-packages.txt            - apt packages required by the binaries at runtime
set -euxo pipefail

TRIK_STUDIO_VERSION=$1
TRIK_STUDIO_SHA=$2

TRIK_STUDIO_REPO=${TRIK_STUDIO_REPO:-https://github.com/trikset/trik-studio.git}
TRIK_PYTHON3_VERSION_MINOR=${TRIK_PYTHON3_VERSION_MINOR:-10}
NUMPY_VERSION=${NUMPY_VERSION:-2.0.1}
SRC_DIR=/src/trik-studio
INSTALL_DIR=/TRIKStudio
PYTHON="python3.${TRIK_PYTHON3_VERSION_MINOR}"

if [ -z "$TRIK_STUDIO_VERSION" ] || [ -z "$TRIK_STUDIO_SHA" ]; then
  echo "Usage: $0 <trik studio version> <trik-studio commit sha>"
  exit 1
fi

# Fetch sources at the pinned commit
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
git init -q .
git remote add origin "$TRIK_STUDIO_REPO"
git fetch -q --depth 1 origin "$TRIK_STUDIO_SHA"
git checkout -q FETCH_HEAD
# TRIK Studio takes its version from `git describe --tags`
git tag "$TRIK_STUDIO_VERSION"
git submodule update -q --init --recursive --depth 1 --jobs "$(nproc)"

# Build dependencies, as in trik-studio CI (Ubuntu branch of install.sh)
env TRIK_PYTHON3_VERSION_MINOR="$TRIK_PYTHON3_VERSION_MINOR" \
  TRIK_PYTHON="$PYTHON" \
  buildScripts/github/install.sh

# Build, as in trik-studio CI (build-ubuntu-release job), without tests.
# Full compiler output exceeds docker build log limit, so it is printed only on failure.
BUILD_LOG=/src/build.log
if ! env TRIK_PYTHON3_VERSION_MINOR="$TRIK_PYTHON3_VERSION_MINOR" \
  CONFIG=release \
  PROJECT=studio \
  ROOT_DIR="$SRC_DIR" \
  BUILD_DIR="$SRC_DIR/build" \
  NEED_COMPILE_DATABASE=false \
  QMAKE_EXTRA="CONFIG+=noPch CONFIG+=ccache CONFIG+=no-sanitizers CONFIG+=warn_off CONFIG+=use_system_qscintilla2 CONFIG+=use_system_quazip" \
  buildScripts/github/build_internal.sh > "$BUILD_LOG" 2>&1; then
  set +x
  echo "TRIK Studio build failed, errors:"
  grep -E -B5 -A5 '(error|Error [0-9]+|not found)' "$BUILD_LOG" | tail -n 300 || :
  echo "Last lines of build log:"
  tail -n 100 "$BUILD_LOG"
  exit 1
fi
tail -n 20 "$BUILD_LOG"

# Older build_internal.sh builds in-source, newer ones in $BUILD_DIR
if [ -x "$SRC_DIR/build/bin/2D-model" ]; then
  BIN_DIR="$SRC_DIR/build/bin"
else
  BIN_DIR="$SRC_DIR/bin"
fi

# Assemble /TRIKStudio
mkdir -p "$INSTALL_DIR/lib"
cp -a "$BIN_DIR" "$INSTALL_DIR/bin"
ln -s bin/trik-studio "$INSTALL_DIR/trik-studio"
find "$INSTALL_DIR/bin" -type f \( -executable -o -name '*.so*' \) -exec strip --strip-unneeded {} + || :

# Python runtime: system stdlib (with lib-dynload) and numpy, like the official installer bundles
PYTHON_RUNTIME_DIR="$INSTALL_DIR/lib/python-runtime"
PYTHON_STDLIB_DIR=$("$PYTHON" -c 'import sysconfig; print(sysconfig.get_paths()["stdlib"])')
cp -a "$PYTHON_STDLIB_DIR" "$PYTHON_RUNTIME_DIR"
rm -rf "$PYTHON_RUNTIME_DIR"/{test,idlelib,tkinter,turtledemo,ensurepip,site-packages,dist-packages,config-*}
"$PYTHON" -m pip install -q --no-cache-dir --no-compile --target "$PYTHON_RUNTIME_DIR" "numpy==$NUMPY_VERSION"
find "$PYTHON_RUNTIME_DIR" -name __pycache__ -type d -prune -exec rm -rf {} +

# Find apt packages which provide shared libraries required by the build
{ find "$INSTALL_DIR" -type f \( -executable -o -name '*.so*' \) -exec ldd {} + 2>/dev/null || :; } \
  | awk '$2 == "=>" && $3 ~ /^\// { print $3 }' \
  | grep -v "^$INSTALL_DIR/" \
  | sort -u \
  | while read -r lib; do
      real=$(realpath "$lib")
      dpkg -S "$lib" 2>/dev/null || dpkg -S "$real" 2>/dev/null \
        || dpkg -S "/usr$real" 2>/dev/null || dpkg -S "${real#/usr}" 2>/dev/null \
        || echo "No package found for $lib" >&2
    done \
  | grep -v '^diversion' | cut -d: -f1 | sort -u > /runtime-packages.txt

cat /runtime-packages.txt
