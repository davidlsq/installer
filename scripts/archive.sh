#!/bin/bash

set -e -o pipefail

while [[ $# -gt 0 ]]; do
  case $1 in
    --directory)
      DIRECTORY="$2"
      shift 2
      ;;
    --host)
      HOST="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    *)
      exit 1
      ;;
  esac
done

_list_secrets () {
  if [ -f "$1/secrets.yml" ]; then
    echo "$1/secrets.yml"
  fi
}

_list_symlinks () {
  if [ -d "$1" ]; then
    find "$1" -type l | xargs -r realpath --relative-to=.
  fi
}

list () {
  _list_secrets "files/$HOST"
  _list_secrets "host_vars/$HOST"
  _list_symlinks "files/$HOST"
  _list_symlinks "host_vars/$HOST"
  _list_symlinks "group_vars"
}

(cd "$DIRECTORY" && list | tar --owner=root --group=root --mode=u=rw,go= -T - -cz) > "$OUTPUT"
