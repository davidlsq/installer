#!/bin/bash

while [[ $# -gt 0 ]]; do
  case $1 in
    --image)
      IMAGE="$2"
      shift 2
      ;;
    *)
      exit 1
      ;;
  esac
done

if [ "$EUID" -ne 0 ]; then echo "Please run as root"
  exit 1
fi

ALL_DISKS=$(diskutil list | grep -e "^/" | awk '{print $1}' | tr '\n' ' ')

SMALL_DISKS=""
for DISK in $ALL_DISKS; do
  SIZE_BYTES=$(diskutil info "$DISK" | grep -F "Disk Size:" | awk '{print $5}')
  SIZE_BYTES="${SIZE_BYTES:1}"
  if (( "$SIZE_BYTES" < 100000000000 )); then
    SMALL_DISKS="$SMALL_DISKS $DISK"
  fi
done

N=1
for DISK in $SMALL_DISKS; do
  PROTOCOL=$(diskutil info "$DISK" | grep -F "Protocol:" | awk '{print $2}')
  SIZE=$(diskutil info "$DISK" | grep -F "Disk Size:" | awk '{print $3" "$4}')
  echo "$N: $DISK $PROTOCOL $SIZE"
  N=$(($N + 1))
done

echo
read -p "Select Disk : " SELECT
echo

DISK="$(echo $SMALL_DISKS | cut -d ' ' -f "$SELECT")"

diskutil umountDisk "$DISK"
dd if="$IMAGE" of="$DISK" bs=2M status=progress
diskutil umountDisk "$DISK"
