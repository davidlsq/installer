#!/bin/bash

ln -sfr $(ls /boot/initrd.img-* | tail -n 1) /boot/initrd.img
ln -sfr $(ls /boot/vmlinuz-* | tail -n 1) /boot/vmlinuz

cp -r /media/cdrom/.install /install
CRON="@reboot /install/install.sh >> /install/install.log 2>&1"
crontab -l | grep -vF "$CRON" | { cat; echo "$CRON"; } | crontab -
