# Grading image: TRIK Studio base image (docker/base) + grading scripts.
# BASE_IMAGE is <user>/trik-studio-base:<trik studio version>-<recipe hash>, see build.sh
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
LABEL maintainer="Viktor Karasev <viktorkarasev27@gmail.com>"
LABEL description="This image is for grading system for TRIK Studio testing system"

WORKDIR /

COPY empty.qrs echo_version.sh generate.sh grade.sh /
RUN chmod +x /echo_version.sh /generate.sh /grade.sh
