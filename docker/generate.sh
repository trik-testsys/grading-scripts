#!/bin/bash

generate_solution() {
    FILE_EXTENSION=$1

    case $FILE_EXTENSION in
        py)
            MODE="python"
        ;;
        js)
            MODE="javascript"
        ;;
        *)
            echo "Unexpected file extension: $FILE_EXTENSION (py or js expected)"
            exit 1
        ;;
    esac

    TMP_SUBMIT="/tmp-submission.qrs"
    cp "/submission.qrs" "$TMP_SUBMIT"

    ./TRIKStudio/bin/2D-model -platform offscreen --only-generate --generate-path "/result/submission.$FILE_EXTENSION" --generate-mode "$MODE" "$TMP_SUBMIT"

    rm "$TMP_SUBMIT"
}

generate_solution $1