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

OUTPUT_TMP="$OUTPUT.tmp"
OUTPUT_INSTALL="$OUTPUT_TMP/install"
OUTPUT_PIGEN="$OUTPUT_TMP/pi-gen"

rm -rf "$OUTPUT_TMP"
docker rm -v pigen_work || true

mkdir "$OUTPUT_TMP"

git clone --depth 1 --branch arm64 https://github.com/RPI-Distro/pi-gen.git "$OUTPUT_PIGEN"

mkdir -p "$OUTPUT_INSTALL/config" "$OUTPUT_INSTALL/host_vars" "$OUTPUT_INSTALL/files"
cp -r roles "$OUTPUT_INSTALL"
cp "$DIRECTORY/$HOST.yml" "$OUTPUT_INSTALL/install.yml"
cp -rL "$DIRECTORY/group_vars" "$OUTPUT_INSTALL/group_vars"
cp -rL "$DIRECTORY/host_vars/$HOST" "$OUTPUT_INSTALL/host_vars/$HOST"
cp -rL "$DIRECTORY/files/$HOST" "$OUTPUT_INSTALL/files/$HOST"

CONFIG_IMAGE="$DIRECTORY/config/${HOST}_image"
cp "$CONFIG_IMAGE/install.sh" "$OUTPUT_INSTALL/install.sh"
cp "$CONFIG_IMAGE/config" "$OUTPUT_PIGEN/config"

cp -r "scripts/raspi/stage" "$OUTPUT_PIGEN/stage"
mkdir "$OUTPUT_PIGEN/stage/00-install/files"
tar -czf "$OUTPUT_PIGEN/stage/00-install/files/install.tar.gz" -C "$OUTPUT_TMP" install

DEB_DOMAIN=debian.proxad.net
DEB_IP="$(host "$DEB_DOMAIN" | awk '/has address/ { print $4 ; exit }')"
sed -i "s/deb\.debian\.org/$DEB_IP/g" "$OUTPUT_PIGEN/stage0/prerun.sh"
(cd "./$OUTPUT_PIGEN" && ./build-docker.sh)
(cd "./$OUTPUT_PIGEN/deploy" && mv *-raspi.img raspi.img)
mv "./$OUTPUT_PIGEN/deploy/raspi.img" "$OUTPUT"
rm -rf "$OUTPUT_TMP"
