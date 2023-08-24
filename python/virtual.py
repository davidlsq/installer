#!/usr/bin/env -S python3 -B

import sys
from pathlib import Path

from ssh import ssh_config, ssh_keygen, ssh_known_host

command = sys.argv[1]
output = Path(sys.argv[2])
output.mkdir()

if command == "configure/keys":
    ssh_keygen(output / "server")
    ssh_keygen(output / "user")
    ssh_keygen(output / "ansible")
elif command == "configure/ssh":
    keys = Path(sys.argv[3])
    known_host = output / "known_host"
    config = output / "config"
    ssh_known_host(known_host, "virtual.local", keys / "server")
    ssh_config(config, known_host, "david", "server.local", keys / "user")
    ssh_config(config, known_host, "ansible", "server.local", keys / "ansible")
