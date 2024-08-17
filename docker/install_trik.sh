#!/bin/bash
set -e

TRIK_STUDIO_VERSION_KIND=$1

TRIK_STUDIO_DIR=TRIKStudio
QS_INSTALL_SCRIPT=install_trik.qs
INSTALLER_DIR=installer
INSTALLER=installer.run
RELEASE_INSTALLER_URL=https://dl.trikset.com/ts/trik-studio-installer-gnu64.run
MASTER_INSTALLER_URL=https://dl.trikset.com/ts/fresh/installer/trik-studio-installer-linux-master.run
INSTALL_COMMAND="env INSTALL_DIR=/$TRIK_STUDIO_DIR ./$INSTALLER_DIR/$INSTALLER --script ./$INSTALLER_DIR/install_trik.qs --platform minimal --verbose"

echo 'ru_RU.UTF-8 UTF-8' > /etc/locale.gen && locale-gen
export LANG=ru_RU.UTF-8
export LANGUAGE=ru_RU:ru
export LC_LANG=ru_RU.UTF-8
export LC_ALL=ru_RU.UTF-8

mkdir $INSTALLER_DIR
mv $QS_INSTALL_SCRIPT ./$INSTALLER_DIR/

case "$TRIK_STUDIO_VERSION_KIND" in
  "release")
    curl --output ./$INSTALLER_DIR/$INSTALLER $RELEASE_INSTALLER_URL
  ;;
  "master")
    curl --output ./$INSTALLER_DIR/$INSTALLER $MASTER_INSTALLER_URL
  ;;
  *)
    echo "Invalid TRIK_STUDIO_VERSION_KIND: $TRIK_STUDIO_VERSION_KIND"
    echo "Allowed TRIK_STUDIO_VERSION_KIND: release, master"
    exit 1
esac

chmod +x ./$INSTALLER_DIR/$INSTALLER
eval "$INSTALL_COMMAND"
rm -r $INSTALLER_DIR

