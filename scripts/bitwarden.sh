#!/bin/bash

set -e -o pipefail

while [[ $# -gt 0 ]]; do
  case $1 in
    --passwords)
      PASSWORDS="${2//,/ }"
      shift 2
      ;;
    --folder)
      FOLDER_NAME="$2"
      shift 2
      ;;
    *)
      exit 1
      ;;
  esac
done

bw logout || true
export BW_SESSION="$(bw login --raw)"

FOLDER_ID=$(bw list folders | jq -r -c --arg FOLDER_NAME "$FOLDER_NAME" '.[] | select(.name == $FOLDER_NAME) | .id')
if [[ -z "$FOLDER_ID" ]]; then
   FOLDER_ID=$(bw get template folder | jq -r -c --arg FOLDER_NAME "$FOLDER_NAME" '.name=$FOLDER_NAME' | bw encode | bw create folder | jq -r -c '.id')
fi

cat $PASSWORDS | grep ":" | while read LINE; do
  LOGIN_NAME=$(echo "$LINE" | cut -d ':' -f 1)
  LOGIN_VALUE=$(echo "$LINE" | cut -d ':' -f 2- | xargs)
  LOGIN_ID=$(bw list items --folderid "$FOLDER_ID" | jq -r -c --arg LOGIN_NAME "$LOGIN_NAME" '.[] | select(.name == $LOGIN_NAME) | .id')
  if [[ -z "$LOGIN_ID" ]]; then
    LOGIN=$(bw get template item.login | jq -r -c --arg LOGIN_NAME "$LOGIN_NAME" --arg LOGIN_VALUE "$LOGIN_VALUE" \
            '.username=$LOGIN_NAME | .password=$LOGIN_VALUE | .totp=null')
    bw get template item | jq -r -c --arg FOLDER_ID "$FOLDER_ID" --arg LOGIN_NAME "$LOGIN_NAME" --argjson LOGIN "$LOGIN" \
      '.folderId=$FOLDER_ID | .name=$LOGIN_NAME | .login=$LOGIN' | \
      bw encode | bw create item > /dev/null
  else
    bw get item "$LOGIN_ID" | jq -r -c --arg LOGIN_VALUE "$LOGIN_VALUE" '.login.password=$LOGIN_VALUE' | \
    bw encode | bw edit item "$LOGIN_ID" > /dev/null
  fi
done
