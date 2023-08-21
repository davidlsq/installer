#!/usr/bin/env python3

from common import Builder

with Builder("debian-x86_64.iso", "server", "server.iso") as builder:
    None
