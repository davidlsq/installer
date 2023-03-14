#!/usr/bin/python3

import getpass
import sys

from pathlib import Path
from passlib.hash import md5_crypt

host   = sys.argv[1]
name   = sys.argv[2]
output = sys.argv[3]

value = getpass.getpass(host + '/' + name + ' ? ')
value = md5_crypt.hash(value)

Path(output).open('a').write('  ' + name + ": " + value + '\n')
