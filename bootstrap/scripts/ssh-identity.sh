#!/bin/bash

cat << EOF >> "$5"
Match user $3 host $4
  GlobalKnownHostsFile $(realpath "$2")
  IdentitiesOnly yes
  IdentityFile $(realpath "$1")
EOF
