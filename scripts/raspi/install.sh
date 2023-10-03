#!/bin/bash

set -e -o pipefail

if [ ! -f /install/expand.done ]; then
  export PATH=$PATH:/usr/sbin/
  /usr/bin/raspi-config --expand-rootfs
  touch /install/expand.done
  /usr/sbin/reboot
  exit 0
fi

if [ ! -f /install/playbook.done ]; then
  source /install/ansible-venv/bin/activate
  ansible-playbook -i "host," -c local "/install/install.yml"
  touch /install/playbook.done
fi