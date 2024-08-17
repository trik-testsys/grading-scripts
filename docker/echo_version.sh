#!/bin/bash
XDG_RUNTIME_DIR=/tmp/runtime-root ./TRIKStudio/trik-studio --version --platform offscreen | grep TRIK | cut -d ' ' -f 4-