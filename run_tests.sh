#!/bin/bash

exit_and_clear() {
  rm -rf ./results
  exit "$1"
}

summarize_results(){
  RESULT_DIRECTORY=$1
  SUM=0

  echo "-------- Results for $RESULT_DIRECTORY --------"
  for file in "$RESULT_DIRECTORY"/*.json
  do
    if grep -q error "$file"; then
      RESULT="ERROR"
    else
      RESULT=$(grep -Eo '[0-9]+' < "$file" | tail -1)
      SUM=$((SUM + RESULT))
    fi

    echo "$file: $RESULT"
  done

  echo "TOTAL: $SUM"
}

run_task() {
  TASK_DIRECTORY=$1
  TASK_NAME=$(basename "$TASK_DIRECTORY")

  echo "Start testing $TASK_NAME"

  mkdir "./results/$TASK_NAME"

  for solution_file in "$TASK_DIRECTORY/solutions/"*;
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

    RESULTS_DIR="./results/$TASK_NAME/$SOLUTION_NAME"
    ACTUAL_SUMMARY_FILE="$RESULTS_DIR/summary.txt"
    mkdir "$RESULTS_DIR"

    ./grade.sh \
      --submission-file "$solution_file" \
      --fields-directory "$TASK_DIRECTORY/fields" \
      --result-directory "$RESULTS_DIR" \
      --image "$IMAGE" || exit_and_clear 1

    summarize_results "$RESULTS_DIR" >> "$RESULTS_DIR/summary.txt"
    echo "diff $EXPECTED_SUMMARY_FILE $ACTUAL_SUMMARY_FILE:"
    diff "$EXPECTED_SUMMARY_FILE" "$ACTUAL_SUMMARY_FILE" || exit_and_clear 1
  done
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

exit_and_clear 0
