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
SCRIPT_FILES=scripts/debian

OUTPUT_TMP="$OUTPUT.tmp"
OUTPUT_EFI="$OUTPUT_TMP/efi.img"
OUTPUT_CONTENT="$OUTPUT_TMP/content"
OUTPUT_INSTALL="$OUTPUT_CONTENT/.install"

rm -rf "$OUTPUT_TMP"
mkdir "$OUTPUT_TMP"

extract-iso-efi "$ISO" "$OUTPUT_EFI"
extract-iso-content "$ISO" "$OUTPUT_CONTENT"

rm -rf "$OUTPUT_CONTENT/install"
ln -sr "$OUTPUT_CONTENT/install."* "$OUTPUT_CONTENT/install"

mkdir -p "$OUTPUT_INSTALL/host_vars" "$OUTPUT_INSTALL/files"
cp -r roles "$OUTPUT_INSTALL"
cp "$ANSIBLE_PLAYBOOK" "$OUTPUT_INSTALL/install.yml"
cp -rL "$ANSIBLE_GROUPVARS" "$OUTPUT_INSTALL"
cp -rL "$ANSIBLE_HOSTVARS" "$OUTPUT_INSTALL/host_vars"
cp -rL "$ANSIBLE_FILES" "$OUTPUT_INSTALL/files"
cp "$CONFIG_IMAGE/"* "$OUTPUT_INSTALL"
cp "$SCRIPT_FILES/"* "$OUTPUT_INSTALL"
chmod +x "$OUTPUT_INSTALL/chroot.sh" "$OUTPUT_INSTALL/install.sh"
ln -sfr "$OUTPUT_INSTALL/grub.cfg" "$OUTPUT_CONTENT/boot/grub/grub.cfg"
chmod -R go-rwx "$OUTPUT_INSTALL"

create-iso "$OUTPUT_EFI" "$OUTPUT_CONTENT" "$OUTPUT_TMP/image.iso"

mv "$OUTPUT_TMP/image.iso" "$OUTPUT"
rm -rf "$OUTPUT_TMP"
