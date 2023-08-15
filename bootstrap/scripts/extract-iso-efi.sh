#!/bin/bash

EFI_LINE=$(fdisk "$1" | grep -F "2: EF" | sed 's/.*\[\(.*\)\].*/\1/')
EFI_START=$(echo "$EFI_LINE" | awk '{print $1}')
EFI_SECTORS=$(echo "$EFI_LINE" | awk '{print $3}')
dd if="$1" bs=512 skip=$EFI_START count=$EFI_SECTORS of="$2" status=none
