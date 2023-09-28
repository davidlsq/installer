#!/bin/bash

ln -sfr $(ls /boot/initrd.img-* | tail -n 1) /boot/initrd.img
ln -sfr $(ls /boot/vmlinuz-* | tail -n 1) /boot/vmlinuz

cp -r /media/cdrom/.config /install
CRON="@reboot [ ! -f /install/playbook.done ] && (sleep 10; /install/playbook.sh >> /install/playbook.log 2>&1) && touch /install/playbook.done"
crontab -l | grep -vF "$CRON" | { cat; echo $CRON; } | crontab -
