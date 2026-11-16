#!/bin/bash

# shellcheck disable=SC2181

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$SCRIPT_DIR/versions.txt"

show_help() {
cat << EOF
Usage: ./build.sh [OPTION]
Build docker image with TrikStudio (built from source) and grading scripts

--help                   Display help

--trik-studio-version    Set TrikStudio version from versions.txt which will be built into image (e.g. 2026.3)

--docker-hub-user        Set which docker-hub username will be used for naming result image

--scripts-version        (Optional) Set grading scripts version used in image tag (default: git describe of this repository)

--no-cache               (Optional) Build image without docker cache

--verbose                Don't supress docker build output

Result image name: <docker-hub-user>/trik-studio:<trik-studio-version>-<scripts-version>

Available TrikStudio versions:
$(list_versions | sed 's/^/  /')
EOF
}

list_versions() {
  grep -Ev '^[[:space:]]*(#|$)' "$VERSIONS_FILE" | awk '{ print $1 }'
}

find_sha() {
  grep -Ev '^[[:space:]]*(#|$)' "$VERSIONS_FILE" | awk -v version="$1" '$1 == version { print $2 }'
}

build() {
  NAME="$DOCKER_HUB_USER/trik-studio:$TRIK_STUDIO_VERSION-$SCRIPTS_VERSION"

  echo "-------------------------- Start building --------------------------"
  echo "TrikStudio version: $TRIK_STUDIO_VERSION ($TRIK_STUDIO_SHA)"
  echo "Scripts version: $SCRIPTS_VERSION"
  echo "Image: $NAME"

  BUILD_OPTS=(
    --build-arg TRIK_STUDIO_VERSION="$TRIK_STUDIO_VERSION"
    --build-arg TRIK_STUDIO_SHA="$TRIK_STUDIO_SHA"
    --tag "$NAME"
  );

  if [ -n "${NO_CACHE}" ]; then
    BUILD_OPTS=("${BUILD_OPTS[@]}" --no-cache);
  fi

  if [ -n "${VERBOSE}" ]; then
    DOCKER_BUILDKIT=1 docker build --progress=plain "${BUILD_OPTS[@]}" "$SCRIPT_DIR/docker"
  else
    DOCKER_BUILDKIT=1 docker build --quiet "${BUILD_OPTS[@]}" "$SCRIPT_DIR/docker" > /dev/null
  fi

  if [ ! $? -eq 0 ]; then
    echo "Failed to build image $NAME"
    exit 1
  fi

  IMAGE_TRIK_VERSION=$(docker run --rm "$NAME" ./echo_version.sh)
  if [ "$IMAGE_TRIK_VERSION" != "$TRIK_STUDIO_VERSION" ]; then
    echo "TrikStudio in image $NAME reports version '$IMAGE_TRIK_VERSION', expected '$TRIK_STUDIO_VERSION'"
    exit 1
  fi

  echo "Image successfully built: $NAME"
  echo "-------------------------- Build finished --------------------------"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --trik-studio-version)
      TRIK_STUDIO_VERSION="$2"
      shift
      shift
      ;;
    --docker-hub-user)
      DOCKER_HUB_USER="$2"
      shift
      shift
      ;;
    --scripts-version)
      SCRIPTS_VERSION="$2"
      shift
      shift
      ;;
    --no-cache)
      NO_CACHE="1"
      shift
      ;;
    --verbose)
      VERBOSE="1"
      shift
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

if [ -z "${TRIK_STUDIO_VERSION}" ]; then
    echo "Required option --trik-studio-version is unspecified"
    exit 1
fi

if [ -z "${DOCKER_HUB_USER}" ]; then
    echo "Required option --docker-hub-user is unspecified"
    exit 1
fi

TRIK_STUDIO_SHA=$(find_sha "$TRIK_STUDIO_VERSION")
if [ -z "${TRIK_STUDIO_SHA}" ]; then
    echo "Unknown --trik-studio-version $TRIK_STUDIO_VERSION, available (see versions.txt):"
    list_versions
    exit 1
fi

if [ -z "${SCRIPTS_VERSION}" ]; then
    SCRIPTS_VERSION=$(git -C "$SCRIPT_DIR" describe --tags --always --dirty 2>/dev/null)
fi

if [ -z "${SCRIPTS_VERSION}" ]; then
    echo "Cannot determine scripts version, specify --scripts-version"
    exit 1
fi

build
