#!/usr/bin/env -S python3 -B

import sys
from pathlib import Path

from password import password_hash
from ssh import ssh_config, ssh_keygen, ssh_known_host

command = sys.argv[1]
output = Path(sys.argv[2])

if command == "configure/keys":
    output.mkdir()
    ssh_keygen(output / "server")
    ssh_keygen(output / "user")
    ssh_keygen(output / "ansible")
elif command == "configure/ssh":
    output.mkdir()
    keys = Path(sys.argv[3])
    known_host = output / "known_host"
    config = output / "config"
    ssh_known_host(known_host, "virtual.local", keys / "server")
    ssh_config(config, known_host, "david", "virtual.local", keys / "user")
    ssh_config(config, known_host, "ansible", "virtual.local", keys / "ansible")
elif command == "configure/password_hash":
    password = Path(sys.argv[3])
    password_hash(password, output, ["root", "user", "ansible"])
