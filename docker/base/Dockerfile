# syntax=docker/dockerfile:1

# TRIK Studio version and commit of https://github.com/trikset/trik-studio (see versions.txt)
ARG TRIK_STUDIO_VERSION
ARG TRIK_STUDIO_SHA

# ---------------------------------------------------------------------------
# Builder: compiles TRIK Studio from source and assembles /TRIKStudio
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG TRIK_STUDIO_VERSION
ARG TRIK_STUDIO_SHA

RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/99norecommends \
    && apt-get -y update \
    && apt-get -y install \
    build-essential \
    ca-certificates \
    git \
    rsync \
    sudo \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

COPY build_trik.sh /build_trik.sh
RUN --mount=type=cache,target=/ccache \
    export CCACHE_DIR=/ccache \
    && test -n "$TRIK_STUDIO_VERSION" && test -n "$TRIK_STUDIO_SHA" \
    && bash /build_trik.sh "$TRIK_STUDIO_VERSION" "$TRIK_STUDIO_SHA"

# ---------------------------------------------------------------------------
# Runtime: TRIK Studio without build tools
# ---------------------------------------------------------------------------
FROM ubuntu:22.04
LABEL maintainer="Viktor Karasev <viktorkarasev27@gmail.com>"
LABEL description="TRIK Studio built from source, base for TRIK Studio testing system grading image"

ARG DEBIAN_FRONTEND=noninteractive
ARG TRIK_STUDIO_VERSION
ARG TRIK_STUDIO_SHA
LABEL trik-studio.version="$TRIK_STUDIO_VERSION"
LABEL trik-studio.sha="$TRIK_STUDIO_SHA"

WORKDIR /

COPY --from=builder /runtime-packages.txt /runtime-packages.txt
RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/99norecommends \
    && apt-get -y update \
    && xargs -a /runtime-packages.txt apt-get -y install \
    locales \
    libpulse0 \
    libqt5multimedia5-plugins \
    fonts-dejavu-core \
    ffmpeg \
    xvfb \
    && echo 'ru_RU.UTF-8 UTF-8' > /etc/locale.gen && locale-gen \
    && rm -rf /var/lib/apt/lists/* /runtime-packages.txt

COPY --from=builder /TRIKStudio /TRIKStudio
# The official installer sets it in its launchers; 2D-model aborts on python code without it
ENV TRIK_PYTHONPATH_BUNDLE_DIR=/TRIKStudio/lib/python-runtime
ENV TRIK_PYTHONPATH=.:/TRIKStudio/lib/python-runtime/base_library.zip:/TRIKStudio/lib/python-runtime/lib-dynload:/TRIKStudio/lib/python-runtime
# Plugins in bin/plugins/* depend on libraries from bin/
RUN echo /TRIKStudio/bin > /etc/ld.so.conf.d/zz-trik-studio.conf && ldconfig
