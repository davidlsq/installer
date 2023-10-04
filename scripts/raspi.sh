#!/bin/bash

set -e -o pipefail

while [[ $# -gt 0 ]]; do
  case $1 in
    --playbook)
      ANSIBLE_PLAYBOOK="$2"
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

ANSIBLE_NAME="$(basename ${ANSIBLE_PLAYBOOK%.yml})"
ANSIBLE_GROUPVARS="$(dirname "$ANSIBLE_PLAYBOOK")/group_vars"
ANSIBLE_HOSTVARS="$(dirname "$ANSIBLE_PLAYBOOK")/host_vars/$ANSIBLE_NAME"
ANSIBLE_FILES="$(dirname "$ANSIBLE_PLAYBOOK")/files/$ANSIBLE_NAME"
CONFIG_IMAGE="$(dirname "$ANSIBLE_PLAYBOOK")/config/${ANSIBLE_NAME}_image"
SCRIPT_FILES=scripts/raspi

OUTPUT_TMP="$OUTPUT.tmp"
OUTPUT_INSTALL="$OUTPUT_TMP/install"
OUTPUT_PIGEN="$OUTPUT_TMP/pi-gen"

rm -rf "$OUTPUT_TMP"
docker rm -v pigen_work || true

mkdir "$OUTPUT_TMP"

git clone --depth 1 --branch arm64 https://github.com/RPI-Distro/pi-gen.git "$OUTPUT_PIGEN"

mkdir -p "$OUTPUT_INSTALL/host_vars" "$OUTPUT_INSTALL/files"
cp -r roles "$OUTPUT_INSTALL"
cp "$ANSIBLE_PLAYBOOK" "$OUTPUT_INSTALL/install.yml"
cp -rL "$ANSIBLE_GROUPVARS" "$OUTPUT_INSTALL"
cp -rL "$ANSIBLE_HOSTVARS" "$OUTPUT_INSTALL/host_vars"
cp -rL "$ANSIBLE_FILES" "$OUTPUT_INSTALL/files"
cp "$CONFIG_IMAGE/install.sh" "$OUTPUT_INSTALL"

cp -r "$CONFIG_IMAGE/config" "$OUTPUT_PIGEN"
cp -r "$SCRIPT_FILES/stage" "$OUTPUT_PIGEN"
mkdir "$OUTPUT_PIGEN/stage/00-install/files"
tar -czf "$OUTPUT_PIGEN/stage/00-install/files/install.tar.gz" -C "$OUTPUT_TMP" install

DEB_DOMAIN=debian.proxad.net
DEB_IP="$(host "$DEB_DOMAIN" | awk '/has address/ { print $4 ; exit }')"
sed -i "s/deb\.debian\.org/$DEB_IP/g" "$OUTPUT_PIGEN/stage0/prerun.sh"
(cd "./$OUTPUT_PIGEN" && ./build-docker.sh)
(cd "./$OUTPUT_PIGEN/deploy" && mv *-raspi.img raspi.img)
mv "./$OUTPUT_PIGEN/deploy/raspi.img" "$OUTPUT"
rm -rf "$OUTPUT_TMP"
