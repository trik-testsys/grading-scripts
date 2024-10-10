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
      echo "Unexpected mode: $MODE"
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

  TWOD_MODEL_OPTS=(
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
    ffmpeg -video_size 1024x768 -framerate 24 -f x11grab -i "$DISPLAY" -draw_mouse 0 "/video/${FIELD_NAME}.mp4" < stop &
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

  if [ -d "/video" ]; then
    echo "q" >> stop
    wait "$FFMPEG_PID"
    rm stop
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
