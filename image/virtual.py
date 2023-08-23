#!/usr/bin/env python3 -B

from image import Builder

with Builder("debian-aarch64.iso", "virtual", "virtual.iso") as builder:
    pass
