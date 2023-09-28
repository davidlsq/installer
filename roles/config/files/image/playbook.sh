#!/bin/bash

set -e

apt-get install -y python3 python3-pip python3-venv python-is-python3

python3 -m venv /install/ansible-venv
source /install/ansible-venv/bin/activate
python3 -m pip install ansible

ansible-playbook -i "host," -c local "/install/install.yml"