#!/bin/bash -e

install files/install.tar.gz "${ROOTFS_DIR}/"

on_chroot << EOF
  tar -zxf /install.tar.gz -C /
  rm /install.tar.gz
  chown -R root:root /install
  chmod -R go=-rwx /install
  chmod u=+x /install/install.sh
EOF
