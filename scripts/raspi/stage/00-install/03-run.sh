#!/bin/bash -e

CRON="@reboot /install/install.sh >> /install/install.log 2>&1"
on_chroot << EOF
crontab -l | grep -vF "$CRON" | { cat; echo "$CRON"; } | crontab -
EOF
