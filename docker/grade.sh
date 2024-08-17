#!/bin/bash

test_submission_single(){
  FIELD_NAME=$1

  TMP_SUBMIT="/tmp-submission.qrs"
  cp "/submission.qrs" "$TMP_SUBMIT"

  PATCHER_OPTS=(
    -f "/fields/${FIELD_NAME}.xml"
  );
  if [ -f /script.py ]; then
    PATCHER_OPTS=(
      "${PATCHER_OPTS[@]}"
      -s /script.py
    );
  fi

  if [ -d "/debug" ]; then
    touch "/debug/${FIELD_NAME}_patcher_options.txt"
    echo "${PATCHER_OPTS[*]} $TMP_SUBMIT" >> "/debug/${FIELD_NAME}_patcher_options.txt"
    cp "/tmp-submission.qrs" "/debug/${FIELD_NAME}.qrs"
  fi

  ./TRIKStudio/bin/patcher "${PATCHER_OPTS[@]}" "$TMP_SUBMIT"

  TWOD_MODEL_OPTS=(
    -platform offscreen
    --close
    --report "/results/${FIELD_NAME}.json"
  );
  if [ -f "/inputs/$FIELD_NAME.txt" ]; then
    cp "/inputs/$FIELD_NAME.txt" "/input.txt"
    TWOD_MODEL_OPTS=(
      "${TWOD_MODEL_OPTS[@]}"
      --input /input.txt
    );
  fi
  if [ -f /script.py ]; then
    TWOD_MODEL_OPTS=(
      "${TWOD_MODEL_OPTS[@]}"
      --mode script
    );
  fi

  if [ -d "/debug" ]; then
    touch "/debug/${FIELD_NAME}_twod_options.txt"
    echo "${TWOD_MODEL_OPTS[*]}" >> "/debug/${FIELD_NAME}_twod_options.txt"
  fi

  ./TRIKStudio/bin/2D-model "${TWOD_MODEL_OPTS[@]}" "$TMP_SUBMIT"

  rm -f "$TMP_SUBMIT"
}

test_submissions(){
  export TRIK_PYTHONPATH_BUNDLE_DIR=/TRIKStudio/lib/python-runtime
  export TRIK_PYTHONPATH=.:"${TRIK_PYTHONPATH_BUNDLE_DIR}/base_library.zip:${TRIK_PYTHONPATH_BUNDLE_DIR}/lib-dynload:${TRIK_PYTHONPATH_BUNDLE_DIR}"

  for field in "/fields/"*;
  do
    if ! [ -f "$field" ]; then
      exit 1
    fi

    FIELD_NAME=$(basename "$field" .xml)
    test_submission_single "${FIELD_NAME}"
  done
}

test_submissions