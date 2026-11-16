#!/bin/bash

# shellcheck disable=SC2181

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$SCRIPT_DIR/versions.txt"
BASE_DIR="$SCRIPT_DIR/docker/base"

show_help() {
cat << EOF
Usage: ./build.sh [OPTION]
Build docker image with TrikStudio and grading scripts.

The image is built on top of a TrikStudio base image
<docker-hub-user>/trik-studio-base:<trik-studio-version>-<trik-studio commit, 12 chars>,
which contains TrikStudio built from source. The base image is taken locally or
pulled from Docker Hub if it exists, otherwise it is built from source (takes a long time).
The tag does not depend on docker/base, so after changing it rebuild base images
with --base build --push-base.

--help                   Display help

--trik-studio-version    Set TrikStudio version from versions.txt (e.g. 2026.3)

--docker-hub-user        Set which docker-hub username will be used for naming images

--scripts-version        (Optional) Set grading scripts version used in image tag (default: git describe of this repository)

--base                   (Optional) How to get base image: auto (default: local, pull or build), pull, build (force rebuild)

--push-base              (Optional) Push base image to Docker Hub if it was built (overwrites existing tag)

--print-base-image       (Optional) Print base image name and exit

--no-cache               (Optional) Build images without docker cache

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

docker_build() {
  if [ -n "${VERBOSE}" ]; then
    DOCKER_BUILDKIT=1 docker build --progress=plain "$@"
  else
    DOCKER_BUILDKIT=1 docker build --quiet "$@" > /dev/null
  fi
}

get_base_image() {
  if [ "$BASE_MODE" = "auto" ] && [ -z "${PUSH_BASE}" ] && docker image inspect "$BASE_IMAGE" > /dev/null 2>&1; then
    echo "Using local base image $BASE_IMAGE"
    return
  fi

  if [ "$BASE_MODE" != "build" ]; then
    echo "Pulling base image $BASE_IMAGE"
    if docker pull --quiet "$BASE_IMAGE" > /dev/null 2>&1; then
      echo "Base image pulled: $BASE_IMAGE"
      return
    fi

    if [ "$BASE_MODE" = "pull" ]; then
      echo "Cannot pull base image $BASE_IMAGE"
      exit 1
    fi
    echo "Base image $BASE_IMAGE not found, building TrikStudio from source"
  fi

  BUILD_OPTS=(
    --build-arg TRIK_STUDIO_VERSION="$TRIK_STUDIO_VERSION"
    --build-arg TRIK_STUDIO_SHA="$TRIK_STUDIO_SHA"
    --tag "$BASE_IMAGE"
  );
  if [ -n "${NO_CACHE}" ]; then
    BUILD_OPTS=("${BUILD_OPTS[@]}" --no-cache);
  fi

  docker_build "${BUILD_OPTS[@]}" "$BASE_DIR"
  if [ ! $? -eq 0 ]; then
    echo "Failed to build base image $BASE_IMAGE"
    exit 1
  fi
  echo "Base image built: $BASE_IMAGE"

  if [ -n "${PUSH_BASE}" ]; then
    docker push "$BASE_IMAGE" || exit 1
    echo "Base image pushed: $BASE_IMAGE"
  fi
}

build() {
  NAME="$DOCKER_HUB_USER/trik-studio:$TRIK_STUDIO_VERSION-$SCRIPTS_VERSION"

  echo "-------------------------- Start building --------------------------"
  echo "TrikStudio version: $TRIK_STUDIO_VERSION ($TRIK_STUDIO_SHA)"
  echo "Base image: $BASE_IMAGE"
  echo "Scripts version: $SCRIPTS_VERSION"
  echo "Image: $NAME"

  get_base_image

  BUILD_OPTS=(
    --build-arg BASE_IMAGE="$BASE_IMAGE"
    --tag "$NAME"
  );
  if [ -n "${NO_CACHE}" ]; then
    BUILD_OPTS=("${BUILD_OPTS[@]}" --no-cache);
  fi

  docker_build "${BUILD_OPTS[@]}" "$SCRIPT_DIR/docker"
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

BASE_MODE="auto"

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
    --base)
      BASE_MODE="$2"
      shift
      shift
      ;;
    --push-base)
      PUSH_BASE="1"
      shift
      ;;
    --print-base-image)
      PRINT_BASE_IMAGE="1"
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

case $BASE_MODE in
  auto|pull|build)
  ;;
  *)
    echo "Incorrect --base $BASE_MODE, available: auto, pull, build"
    exit 1
  ;;
esac

TRIK_STUDIO_SHA=$(find_sha "$TRIK_STUDIO_VERSION")
if [ -z "${TRIK_STUDIO_SHA}" ]; then
    echo "Unknown --trik-studio-version $TRIK_STUDIO_VERSION, available (see versions.txt):"
    list_versions
    exit 1
fi

BASE_IMAGE="$DOCKER_HUB_USER/trik-studio-base:$TRIK_STUDIO_VERSION-${TRIK_STUDIO_SHA:0:12}"

if [ -n "${PRINT_BASE_IMAGE}" ]; then
    echo "$BASE_IMAGE"
    exit 0
fi

if [ -z "${SCRIPTS_VERSION}" ]; then
    SCRIPTS_VERSION=$(git -C "$SCRIPT_DIR" describe --tags --always --dirty 2>/dev/null)
fi

if [ -z "${SCRIPTS_VERSION}" ]; then
    echo "Cannot determine scripts version, specify --scripts-version"
    exit 1
fi

build
