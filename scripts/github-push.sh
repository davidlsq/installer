#!/bin/bash

set -e -o pipefail

while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      FILE="$2"
      shift 2
      ;;
    --var)
      VAR="$2"
      shift 2
      ;;
    *)
      exit 1
      ;;
  esac
done

cat "$FILE" | base64 -w 0 | gh secret set "$VAR" -R davidlsq/installer
