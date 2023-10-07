#!/bin/bash

set -e -o pipefail

TMP=$(mktemp -d)

trap "rm -r $TMP" EXIT

USER=$(echo "$1" | cut -d '@' -f 1)
HOST=$(echo "$1" | cut -d '@' -f 2)
shift 1

touch "$TMP/user"; chmod u=rw,go= $_
echo "$SSH_USER_KEY" | base64 -d > "$TMP/user"
echo "$HOST  $(echo "$SSH_HOST_KEY" | base64 -d)" > "$TMP/known_host"
ssh "$USER@$HOST" -i "$TMP/user" -o "GlobalKnownHostsFile=$TMP/known_host" $@
