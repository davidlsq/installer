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

trap "rm -rf $OUTPUT_TMP" EXIT

rm -rf "$OUTPUT_TMP"
docker rm -v pigen_work || true

mkdir "$OUTPUT_TMP"

git clone --depth 1 --branch arm64 https://github.com/RPI-Distro/pi-gen.git "$OUTPUT_PIGEN"

mkdir "$OUTPUT_INSTALL"
cp -r roles "$OUTPUT_INSTALL"
cp "$DIRECTORY/$HOST.yml" "$OUTPUT_INSTALL/install.yml"
test -d "$DIRECTORY/group_vars" \
  && cp -rL "$DIRECTORY/group_vars" "$OUTPUT_INSTALL/group_vars"
for DIR in host_vars files; do
  test -d "$DIRECTORY/$DIR" \
    && cp -r "$DIRECTORY/$DIR" "$OUTPUT_INSTALL/$DIR"
  test -d "$DIRECTORY/$DIR/$HOST" \
    && rm -rf "$OUTPUT_INSTALL/$DIR/$HOST" \
    && cp -rL "$DIRECTORY/$DIR/$HOST" "$OUTPUT_INSTALL/$DIR/$HOST"
done

CONFIG_IMAGE="$DIRECTORY/config/playbook/${HOST}_image"
cp "$CONFIG_IMAGE/install.sh" "$OUTPUT_INSTALL/install.sh"
cp "$CONFIG_IMAGE/config" "$OUTPUT_PIGEN/config"

STAGE="$OUTPUT_PIGEN/stage"
STAGE_FILES="$STAGE/00-install/files"
cp -r "scripts/raspi/stage" "$STAGE"
mkdir "$STAGE_FILES"
cp "$CONFIG_IMAGE/config" "$STAGE_FILES"
tar -czf "$STAGE_FILES/install.tar.gz" -C "$OUTPUT_TMP" install

# Avoid DNS errors during debian bootstrap
DEB_DOMAIN=debian.proxad.net
DEB_IP="$(host "$DEB_DOMAIN" | awk '/has address/ { print $4 ; exit }')"
sed -i "s/deb\.debian\.org/$DEB_IP/g" "$OUTPUT_PIGEN/stage0/prerun.sh"

# Remove pi-gen DNS config
rm -r "$OUTPUT_PIGEN/export-image/03-network"

(cd "$OUTPUT_PIGEN" && ./build-docker.sh)
(cd "$OUTPUT_PIGEN/deploy" && mv *-raspi.img raspi.img)
mv "$OUTPUT_PIGEN/deploy/raspi.img" "$OUTPUT"
