#!/usr/bin/env python3 -B

from image import Builder

with Builder("debian-x86_64.iso", "server", "server.iso") as builder:
    pass
