#!/bin/bash

# shellcheck disable=SC2054
# shellcheck disable=SC2140
# shellcheck disable=SC2181

run_docker_generate() {
  if [ -n $"${VERBOSE}" ]; then
    docker run "$@" /bin/bash /generate.sh $MODE
  else
    docker run "$@" /bin/bash /generate.sh $MODE > /dev/null
  fi

  if [ ! $? -eq 0 ]; then
    exit 1
  fi
}

generate() {

  echo "-------------------------- Start generating --------------------------"
  echo "Submission file: $SUBMISSION_FILE"
  echo "Result directory: $RESULT_DIRECTORY"
  echo "Mode: $MODE"


  MOUNT_OPTS=(
    -e MODE="$MODE"
    --mount type=bind,source="$SUBMISSION_FILE",target="/submission.qrs",readonly
    --mount type=bind,source="$RESULT_DIRECTORY",target="/result"
  );

  OPTS=(
    --rm
    "${MOUNT_OPTS[@]}"
    "$IMAGE"
  );


  run_docker_generate "${OPTS[@]}"

  echo "Generating successfully finished"
  echo "-------------------------- Generating finished --------------------------"
}

show_help() {
cat << EOF
Usage: ./generate.sh [OPTION]
Generate python or javascript submission from TRIKStudio qrs

--help                Display help

--mode                Set generation mode (py|js)

--submission-file     Set submission file

--result-directory    Set directory which will contains generation result

--image               Set TrikStudio image which will be used for generating

--verbose             Don't supress TrikStudio grading output

EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --submission-file)
      SUBMISSION_FILE="$2"
      shift
      shift
      ;;
    --mode)
      MODE="$2"
      shift
      shift
      ;;
    --result-directory)
      RESULT_DIRECTORY="$2"
      shift
      shift
      ;;
    --image)
      IMAGE="$2"
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

case $MODE in
  py|js)
  ;;
  *)
    echo "Unexpected --mode: $MODE"
    exit 1
  ;;
esac

if [ -z "${SUBMISSION_FILE}" ]; then
    echo "Required option --submission-file is unspecified"
    exit 1
fi

if [ ! -f "${SUBMISSION_FILE}" ]; then
    echo "$SUBMISSION_FILE doesn't exists"
    exit 1
fi

if [ -z "${RESULT_DIRECTORY}" ]; then
    echo "Required option --result-directory is unspecified"
    exit 1
fi

if [ ! -d "${RESULT_DIRECTORY}" ]; then
    echo "$RESULT_DIRECTORY doesn't exists"
    exit 1
fi


generate
