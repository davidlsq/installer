#!/bin/bash

set -e -o pipefail

while [[ $# -gt 0 ]]; do
  case $1 in
    --image)
      IMAGE="$2"
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

RASPBERRYPI_CONFIG="$IMAGE/config/raspi"
SCRIPT_FILES=scripts/raspi

OUTPUT_TMP="$OUTPUT.tmp"
OUTPUT_INSTALL="$OUTPUT_TMP/install"
OUTPUT_PIGEN="$OUTPUT_TMP/pi-gen"

rm -rf "$OUTPUT_TMP"
docker rm -v pigen_work || true

mkdir "$OUTPUT_TMP"

git clone --depth 1 --branch arm64 https://github.com/RPI-Distro/pi-gen.git "$OUTPUT_PIGEN"

mkdir "$OUTPUT_INSTALL"
cp -r roles "$OUTPUT_INSTALL"
cp -rL "$IMAGE/files" "$OUTPUT_INSTALL"
cp -rL "$IMAGE/group_vars" "$OUTPUT_INSTALL"
cp "$IMAGE/install.yml" "$OUTPUT_INSTALL"
cp "$SCRIPT_FILES/install.sh" "$OUTPUT_INSTALL"

cp -r "$RASPBERRYPI_CONFIG/config" "$OUTPUT_PIGEN"
cp -r "$SCRIPT_FILES/stage" "$OUTPUT_PIGEN"
mkdir "$OUTPUT_PIGEN/stage/00-install/files"
tar -czf "$OUTPUT_PIGEN/stage/00-install/files/install.tar.gz" -C "$OUTPUT_TMP" install
touch "./$OUTPUT_TMP/pi-gen/stage/EXPORT_IMAGE"

(cd "./$OUTPUT_PIGEN" && ./build-docker.sh)
(cd "./$OUTPUT_PIGEN/deploy" && mv *-raspi.img raspi.img)
mv "./$OUTPUT_PIGEN/deploy/raspi.img" "$OUTPUT"
rm -rf "$OUTPUT_TMP"
