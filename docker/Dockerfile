FROM ubuntu:22.04
MAINTAINER Viktor Karasev <viktorkarasev27@gmail.com>
LABEL Description="This image is for grading system for TRIK Studio testing system"

# Updating system and installing TRIK studio dependencies
WORKDIR /
ARG DEBIAN_FRONTEND=noninteractive

RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/99norecommends \
    && apt-get -y update \
    && apt-get -y install \
    apt-utils \
    wget \
    curl \
    libpulse0 \
    locales \
    ca-certificates \
    libxkbcommon-x11-0 \
    libfontconfig \
    libx11-xcb1 \
    libxrender1 \
    libxcb-glx0 \
    libxext6 \
    libsm6 \
    ffmpeg \
    xvfb \
    python3 \
    python3-dev \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    && apt-get autoremove -y \
    && apt-get clean -y

ARG TRIK_STUDIO_VERSION_KIND="master"

# Install TRIK studio
WORKDIR /

COPY empty.qrs empty.qrs
COPY install_trik.qs install_trik.qs
COPY install_trik.sh install_trik.sh
COPY echo_version.sh echo_version.sh
RUN chmod +x install_trik.qs \
    && chmod +x install_trik.sh \
    && chmod +x echo_version.sh \
    && ./install_trik.sh $TRIK_STUDIO_VERSION_KIND
COPY grade.sh grade.sh
