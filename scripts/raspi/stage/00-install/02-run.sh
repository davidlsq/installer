#!/bin/bash -e

install files/install.tar.gz "${ROOTFS_DIR}/"

on_chroot << EOF
  tar -zxf /install.tar.gz -C /
  rm /install.tar.gz
  python3 -m venv /install/ansible-venv
  source /install/ansible-venv/bin/activate
  python3 -m pip install ansible
  chown -R root:root /install
  chmod -R go=-rwx /install
  chmod u=+x /install/install.sh
EOF
