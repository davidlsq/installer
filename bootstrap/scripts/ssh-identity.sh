#!/bin/bash

mkdir -p "${HOME}/.ssh/keys"
chmod u=rwx,go= "$_"

cp "$1" "${HOME}/.ssh/keys/${3}@${2}"
cp "${1}.pub" "${HOME}/.ssh/keys/${3}@${2}.pub"

mkdir -p "${HOME}/.ssh/config.d"
chmod u=rwx,go= "$_"
cat << EOF > "${HOME}/.ssh/config.d/${3}@${2}"
Match user ${3} host ${2}
  IdentitiesOnly yes
  IdentityFile ~/.ssh/keys/${3}@${2}
EOF
