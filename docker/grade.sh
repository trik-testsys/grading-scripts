#!/bin/bash

test_submission_single(){
  FIELD_NAME=$1
  TMP_SUBMIT="/tmp-submission.qrs"

  case $MODE in
    py|js)
      cp "/empty.qrs" "$TMP_SUBMIT"
    ;;
    qrs)
      cp "/submission.qrs" "$TMP_SUBMIT"
    ;;
    *)
      echo "Unexpected mode: $MODE (expected py, js or qrs)"
      exit 1
    ;;
  esac

  PATCHER_OPTS=(
    -f "/fields/${FIELD_NAME}.xml"
  );

  case $MODE in
    py|js)
      PATCHER_OPTS=(
        "${PATCHER_OPTS[@]}"
        -s "/submission.$MODE"
      );
    ;;
  esac

  if [ -d "/debug" ]; then
    touch "/debug/${FIELD_NAME}_patcher_options.txt"
    echo "${PATCHER_OPTS[*]} $TMP_SUBMIT" >> "/debug/${FIELD_NAME}_patcher_options.txt"
    cp "/tmp-submission.qrs" "/debug/${FIELD_NAME}.qrs"
  fi

  ./TRIKStudio/bin/patcher "${PATCHER_OPTS[@]}" "$TMP_SUBMIT"
  PATCHER_EXIT_CODE=$?
  if [ "$PATCHER_EXIT_CODE" -ne 0 ]; then
    echo "Patcher failed for field ${FIELD_NAME} with exit code ${PATCHER_EXIT_CODE}: ${PATCHER_OPTS[*]} $TMP_SUBMIT" >&2
    exit 3
  fi

  TWOD_MODEL_OPTS=(
    --close
    --report "/results/${FIELD_NAME}.json"
    --delay-before-exit 2000
  );

  if [ -f "/inputs/$FIELD_NAME.txt" ]; then
    cp "/inputs/$FIELD_NAME.txt" "/input.txt"
    TWOD_MODEL_OPTS=(
      "${TWOD_MODEL_OPTS[@]}"
      --input /input.txt
    );
  fi

  case $MODE in
    py|js)
      TWOD_MODEL_OPTS=(
        "${TWOD_MODEL_OPTS[@]}"
        --mode script
      );
    ;;
  esac

  if [ -d "/video" ]; then
    touch stop
    ffmpeg -hide_banner -loglevel error -nostats -video_size 1024x768 -framerate 24 -f x11grab -i "$DISPLAY" -pix_fmt yuv420p -draw_mouse 0 "/video/${FIELD_NAME}.mp4" < stop &
    FFMPEG_PID=$!
  else
    TWOD_MODEL_OPTS=(
      "${TWOD_MODEL_OPTS[@]}"
      -platform offscreen
    );
  fi

  if [ -d "/debug" ]; then
    touch "/debug/${FIELD_NAME}_twod_options.txt"
    echo "${TWOD_MODEL_OPTS[*]}" >> "/debug/${FIELD_NAME}_twod_options.txt"
    cp "/tmp-submission.qrs" "/debug/${FIELD_NAME}_patched.qrs"
  fi

  ./TRIKStudio/bin/2D-model "${TWOD_MODEL_OPTS[@]}" "$TMP_SUBMIT"
  TWOD_MODEL_EXIT_CODE=$?

  if [ -d "/video" ]; then
    echo "q" >> stop
    wait "$FFMPEG_PID"
    rm stop
  fi

  # 2D-model exits with 1 when the program ends with an error, so only a signal (code 128 + N) means a crash.
  if [ "$TWOD_MODEL_EXIT_CODE" -ge 128 ]; then
    echo "2D-model crashed for field ${FIELD_NAME} with exit code ${TWOD_MODEL_EXIT_CODE}: ${TWOD_MODEL_OPTS[*]} $TMP_SUBMIT" >&2
    exit 4
  fi

  rm -f "$TMP_SUBMIT"
}

test_submissions(){
  export TRIK_PYTHONPATH_BUNDLE_DIR=/TRIKStudio/lib/python-runtime
  export TRIK_PYTHONPATH=.:"${TRIK_PYTHONPATH_BUNDLE_DIR}/base_library.zip:${TRIK_PYTHONPATH_BUNDLE_DIR}/lib-dynload:${TRIK_PYTHONPATH_BUNDLE_DIR}"

  export DISPLAY=:99
  Xvfb $DISPLAY -screen 0 1024x768x24 &

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
