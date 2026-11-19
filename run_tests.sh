#!/bin/bash

exit_and_clear() {
  rm -rf ./results
  exit "$1"
}

summarize_results(){
  RESULT_DIRECTORY=$1
  SUM=0

  for file in "$RESULT_DIRECTORY"/*.json
  do
    if grep -q error "$file"; then
      RESULT="ERROR"
    else
      RESULT=$(grep -Eo '[0-9]+' < "$file" | tail -1)
      SUM=$((SUM + RESULT))
    fi

    echo "$(basename "$file"): $RESULT"
  done

  echo "TOTAL: $SUM"
}

run_task() {
  TASK_DIRECTORY=$1
  TASK_NAME=$(basename "$TASK_DIRECTORY")

  echo "Start testing $TASK_NAME"

  mkdir "./results/$TASK_NAME"

  for solution_file in "$TASK_DIRECTORY/solutions/"*.qrs;
  do
    if ! [ -f "$solution_file" ]; then
      echo "Unexpected directory: $solution_file"
      exit_and_clear 1
    fi

    SOLUTION_NAME=$(basename "$solution_file" .qrs)
    EXPECTED_SUMMARY_FILE="$TASK_DIRECTORY/expected/$SOLUTION_NAME.txt"


    if ! [ -f "$EXPECTED_SUMMARY_FILE" ]; then
      echo "Expected summary file not found for solution: $solution_file"
      exit_and_clear 1
    fi

    for mode in py js;
    do
      ./generate.sh --submission-file \
        "$TASK_DIRECTORY/solutions/$SOLUTION_NAME.qrs" \
        --mode $mode \
        --result-directory "./results/$TASK_NAME/generated_solutions" \
        --image "$IMAGE"
    done


    RESULTS_DIR="./results/$TASK_NAME/$SOLUTION_NAME/qrs"
    ACTUAL_SUMMARY_FILE="$RESULTS_DIR/summary.txt"
    mkdir -p "$RESULTS_DIR"

    SUBMISSION_FILE="$TASK_DIRECTORY/solutions/$SOLUTION_NAME.qrs"

    ./grade.sh \
      --mode qrs \
      --submission-file "$SUBMISSION_FILE" \
      --fields-directory "$TASK_DIRECTORY/fields" \
      --video-directory "$RESULTS_DIR" \
      --result-directory "$RESULTS_DIR" \
      --debug-directory "$RESULTS_DIR" \
      --image "$IMAGE" || exit_and_clear 1

    summarize_results "$RESULTS_DIR" >> "$ACTUAL_SUMMARY_FILE"
    echo "diff $EXPECTED_SUMMARY_FILE $ACTUAL_SUMMARY_FILE:"
    diff "$EXPECTED_SUMMARY_FILE" "$ACTUAL_SUMMARY_FILE" || exit_and_clear 1

  done
}

# Fields of a failure case without its own fields directory
FAILURE_FIELDS_DIRECTORY="./examples/straight_line/fields"

run_failure_case() {
  CASE_DIRECTORY=$1
  CASE_NAME=$(basename "$CASE_DIRECTORY")
  EXPECTED_EXIT_CODE=$(cat "$CASE_DIRECTORY/expected_exit_code.txt")

  echo "Start testing failure $CASE_NAME"

  FIELDS_DIRECTORY="$CASE_DIRECTORY/fields"
  if ! [ -d "$FIELDS_DIRECTORY" ]; then
    FIELDS_DIRECTORY="$FAILURE_FIELDS_DIRECTORY"
  fi

  RESULTS_DIR="./results/failures/$CASE_NAME"
  mkdir -p "$RESULTS_DIR"

  ./grade.sh \
    --mode qrs \
    --submission-file "$CASE_DIRECTORY/submission.qrs" \
    --fields-directory "$FIELDS_DIRECTORY" \
    --video-directory "$RESULTS_DIR" \
    --result-directory "$RESULTS_DIR" \
    --image "$IMAGE"
  ACTUAL_EXIT_CODE=$?

  echo "Exit code of $CASE_NAME: expected $EXPECTED_EXIT_CODE, actual $ACTUAL_EXIT_CODE"
  if [ "$ACTUAL_EXIT_CODE" -ne "$EXPECTED_EXIT_CODE" ]; then
    exit_and_clear 1
  fi
}

if [[ -z "${IMAGE}" ]]; then
  echo "IMAGE env var undefined"
  exit_and_clear 1
fi

mkdir results
echo "Run test for image $IMAGE"

for task in ./examples/*;
do
  run_task "$task"
done

for failure_case in ./failures/*;
do
  run_failure_case "$failure_case"
done

exit_and_clear 0