#!/bin/bash

ssh-keygen -C "" -N "" -t ed25519 -f "$1" > /dev/null
