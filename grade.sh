#!/bin/bash

# shellcheck disable=SC2054
# shellcheck disable=SC2140
# shellcheck disable=SC2181

run_docker_grade() {
  if [ -n $"${VERBOSE}" ]; then
    docker run "$@" /bin/bash /grade.sh
  else
    docker run "$@" /bin/bash /grade.sh > /dev/null
  fi

  if [ ! $? -eq 0 ]; then
    exit 1
  fi
}

grade() {

  echo "-------------------------- Start grading --------------------------"
  echo "Submission file: $SUBMISSION_FILE"
  echo "Script file: $SCRIPT_FILE"
  echo "Fields directory: $FIELDS_DIRECTORY"
  echo "Inputs directory: $INPUTS_DIRECTORY"
  echo "Result directory: $RESULT_DIRECTORY"
  echo "Debug directory: $DEBUG_DIRECTORY"


  MOUNT_OPTS=(
    --mount type=bind,source="$SUBMISSION_FILE",target="/submission.qrs",readonly
    --mount type=bind,source="$FIELDS_DIRECTORY",target="/fields",readonly
    --mount type=bind,source="$RESULT_DIRECTORY",target="/results"
  );

  if [ -n "${INPUTS_DIRECTORY}" ]; then
      MOUNT_OPTS=(
        --mount type=bind,source="$INPUTS_DIRECTORY",target="/inputs",readonly
        "${MOUNT_OPTS[@]}"
      );
  fi

  if [ -n "${VIDEO_DIRECTORY}" ]; then
      MOUNT_OPTS=(
        --mount type=bind,source="$VIDEO_DIRECTORY",target="/video"
        "${MOUNT_OPTS[@]}"
      );
  fi

  if [ -n "${SCRIPT_FILE}" ]; then
      MOUNT_OPTS=(
        --mount type=bind,source="$SCRIPT_FILE",target="/script.py",readonly
        "${MOUNT_OPTS[@]}"
      );
  fi

  if [ -n "${DEBUG_DIRECTORY}" ]; then
      MOUNT_OPTS=(
        --mount type=bind,source="$DEBUG_DIRECTORY",target="/debug"
        "${MOUNT_OPTS[@]}"
      );
  fi

  OPTS=(
    --rm
    "${MOUNT_OPTS[@]}"
    "$IMAGE"
  );

  run_docker_grade "${OPTS[@]}"

  echo "Grading successfully finished"
  echo "-------------------------- Grading finished --------------------------"
}

show_help() {
cat << EOF
Usage: ./grade.sh [OPTION]
Grade TrikStudio submission with specified fields

--help                Display help

--submission-file     Set submission file

--script-file         (Optional) Set submission script file

--fields-directory    Set directory which contains fields

--inputs-directory    (Optional) Set directory which contains inputs for corresponding fields

--video-directory     (Optional) Set directory which will contains recorded screen for each field passing

--result-directory    Set directory which will contains grading results

--debug-directory     (Optional) Set directory which will contains patched submissions, patcher args, 2D-model args

--image               Set TrikStudio image which will be used for grading

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
    --script-file)
      SCRIPT_FILE="$2"
      shift
      shift
      ;;
    --fields-directory)
      FIELDS_DIRECTORY="$2"
      shift
      shift
      ;;
    --inputs-directory)
      INPUTS_DIRECTORY="$2"
      shift
      shift
      ;;
    --video-directory)
      VIDEO_DIRECTORY="$2"
      shift
      shift
      ;;
    --result-directory)
      RESULT_DIRECTORY="$2"
      shift
      shift
      ;;
    --debug-directory)
      DEBUG_DIRECTORY="$2"
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

if [ -z "${SUBMISSION_FILE}" ]; then
    echo "Required option --submission-file is unspecified"
    exit 1
fi

if [ ! -f "${SUBMISSION_FILE}" ]; then
    echo "$SUBMISSION_FILE doesn't exists"
    exit 1
fi

if [ -n "${SCRIPT_FILE}" ] && [ ! -f "${SCRIPT_FILE}" ]; then
    echo "--script-file specified, but $SCRIPT_FILE doesn't exists"
    exit 1
fi

if [ -z "${FIELDS_DIRECTORY}" ]; then
    echo "Required option --fields-directory is unspecified"
    exit 1
fi

if [ ! -d "${FIELDS_DIRECTORY}" ]; then
    echo "$FIELDS_DIRECTORY doesn't exists"
    exit 1
fi

if [ -n "${INPUTS_DIRECTORY}" ] && [ ! -d "${INPUTS_DIRECTORY}" ]; then
    echo "--inputs-directory specified, but $INPUTS_DIRECTORY doesn't exists"
    exit 1
fi

if [ -n "${VIDEO_DIRECTORY}" ] && [ ! -d "${VIDEO_DIRECTORY}" ]; then
    echo "--video-directory specified, but $VIDEO_DIRECTORY doesn't exists"
    exit 1
fi

if [ -n "${DEBUG_DIRECTORY}" ] && [ ! -d "${DEBUG_DIRECTORY}" ]; then
    echo "--debug-directory specified, but $DEBUG_DIRECTORY doesn't exists"
    exit 1
fi

if [ -z "${RESULT_DIRECTORY}" ]; then
    echo "Required option --fields-directory is unspecified"
    exit 1
fi

if [ ! -d "${RESULT_DIRECTORY}" ]; then
    echo "$RESULT_DIRECTORY doesn't exists"
    exit 1
fi

grade