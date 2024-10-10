#!/bin/bash

# shellcheck disable=SC2181

show_help() {
cat << EOF
Usage: ./build.sh [OPTION]
Build docker image with TrikStudio and grading script

--help                        Display help

--trik-studio-version-kind    Set which TrikStudio distribution will be used for image building (master or release)

--docker-hub-user             Set which docker-hub username will be used for naming result image

--verbose                     Don't supress docker build output

EOF
}

create_name() {
  echo "$DOCKER_HUB_USER/trik-studio:$TRIK_STUDIO_VERSION_KIND-$1-$(date +%F)"
}

build() {

  echo "-------------------------- Start building --------------------------"
  echo "TrikStudio version kind: $TRIK_STUDIO_VERSION_KIND"
  echo "DockerHub user: $DOCKER_HUB_USER"

  if [ -n $"${VERBOSE}" ]; then
    docker build --build-arg TRIK_STUDIO_VERSION_KIND="$TRIK_STUDIO_VERSION_KIND" ./docker
  else
    docker build --build-arg TRIK_STUDIO_VERSION_KIND="$TRIK_STUDIO_VERSION_KIND" ./docker > /dev/null
  fi

  if [ ! $? -eq 0 ]; then
    exit 1
  fi

  CURRENT_DOCKER_IMAGE_NAME=$(docker images -q | head -n 1)
  RAW_VERSION=$(docker run --rm "$CURRENT_DOCKER_IMAGE_NAME" ./echo_version.sh)
  NAME=$(create_name "$RAW_VERSION")

  docker tag "$CURRENT_DOCKER_IMAGE_NAME" "$NAME"

  echo "Image successfully built: $NAME"
  echo "-------------------------- Build finished --------------------------"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --trik-studio-version-kind)
      TRIK_STUDIO_VERSION_KIND="$2"
      shift
      shift
      ;;
    --docker-hub-user)
      DOCKER_HUB_USER="$2"
      shift
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

if [ -z "${TRIK_STUDIO_VERSION_KIND}" ]; then
    echo "Required option --trik-studio-version-kind is unspecified"
    exit 1
fi

if [ -z "${DOCKER_HUB_USER}" ]; then
    echo "Required option --docker-hub-user is unspecified"
    exit 1
fi

case $TRIK_STUDIO_VERSION_KIND in
  "release");;
  "master");;
  *)
    echo "Incorrect --trik-studio-version-kind, available: master, release"
    exit 1
  ;;
esac

build
