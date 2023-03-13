#!/bin/bash

mkdir "$2"
/usr/bin/bsdtar -xf "$1" -C "$2"
chmod -R +w "$2"
