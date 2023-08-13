#!/usr/bin/python3

import getpass
import sys

from pathlib import Path

host   = sys.argv[1]
name   = sys.argv[2]
output = sys.argv[3]

value = getpass.getpass(host + '/' + name + ' ? ')

Path(output).open('a').write('  ' + name + ": " + value + '\n')
