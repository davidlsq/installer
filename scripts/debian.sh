#!/bin/bash

set -e -o pipefail

extract-iso-efi () {
  if [[ "$OSTYPE" == "linux"* ]]; then
    EFI_LINE=$(fdisk -l "$1" | grep -F "${1}2")
    EFI_START=$(echo "$EFI_LINE" | awk '{print $2}')
    EFI_SECTORS=$(echo "$EFI_LINE" | awk '{print $3}')
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    EFI_LINE=$(fdisk "$1" | grep -F "2: EF" | sed 's/.*\[\(.*\)\].*/\1/')
    EFI_START=$(echo "$EFI_LINE" | awk '{print $1}')
    EFI_SECTORS=$(echo "$EFI_LINE" | awk '{print $3}')
  else
    exit 1
  fi
  dd if="$1" bs=512 skip=$EFI_START count=$EFI_SECTORS of="$2" status=none
}

extract-iso-content () {
  mkdir "$2"
  bsdtar -xf "$1" -C "$2"
  chmod -R +w "$2"
}

create-iso () {
  chmod -R -w "$2"
  xorriso \
    -as mkisofs \
    -quiet \
    -V CDROM \
    -R -uid 0 -gid 0 \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -append_partition 2 0xef "$1" \
    -partition_cyl_align all \
    -o "$3" \
    "$2"
  chmod -R +w "$2"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --iso)
      ISO="$2"
      shift 2
      ;;
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
OUTPUT_EFI="$OUTPUT_TMP/efi.img"
OUTPUT_CONTENT="$OUTPUT_TMP/content"
OUTPUT_INSTALL="$OUTPUT_CONTENT/.install"

trap "rm -rf $OUTPUT_TMP" EXIT

rm -rf "$OUTPUT_TMP"
mkdir "$OUTPUT_TMP"

extract-iso-efi "$ISO" "$OUTPUT_EFI"
extract-iso-content "$ISO" "$OUTPUT_CONTENT"

rm -rf "$OUTPUT_CONTENT/install"
ln -sr "$OUTPUT_CONTENT/install."* "$OUTPUT_CONTENT/install"

mkdir "$OUTPUT_INSTALL"
cp -r roles "$OUTPUT_INSTALL/roles"
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
cp "$DIRECTORY/config/playbook/${HOST}_image/"* "$OUTPUT_INSTALL"
cp "scripts/debian/"* "$OUTPUT_INSTALL"
chmod +x "$OUTPUT_INSTALL/chroot.sh" "$OUTPUT_INSTALL/install.sh"
ln -sfr "$OUTPUT_INSTALL/grub.cfg" "$OUTPUT_CONTENT/boot/grub/grub.cfg"
chmod -R go-rwx "$OUTPUT_INSTALL"

create-iso "$OUTPUT_EFI" "$OUTPUT_CONTENT" "$OUTPUT_TMP/image.iso"

mv "$OUTPUT_TMP/image.iso" "$OUTPUT"
