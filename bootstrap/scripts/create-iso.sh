#!/bin/bash

xorriso \
  -as mkisofs \
  -quiet \
  -V CDROM \
  -R -uid 0 -gid 0 \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -append_partition 2 0xef "$2" \
  -partition_cyl_align all \
  -o "$3" \
  "$1"
