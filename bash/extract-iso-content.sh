#!/bin/bash

mkdir "$2"
bsdtar -xf "$1" -C "$2"
chmod -R +w "$2"
