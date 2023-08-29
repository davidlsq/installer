#!/usr/bin/env -S python3 -B

import sys
from pathlib import Path

from image import image_build
from password import password_hash
from ssh import ssh_config, ssh_keygen, ssh_known_host

command = sys.argv[1]
output = Path(sys.argv[2])

if command == "keys":
    output.mkdir()
    ssh_keygen(output / "server")
    ssh_keygen(output / "user")
    ssh_keygen(output / "ansible")
elif command == "ssh":
    output.mkdir()
    keys = Path(sys.argv[3])
    known_host = output / "known_host"
    config = output / "config"
    ssh_known_host(known_host, "server.local", keys / "server")
    ssh_known_host(known_host, "server.davidlsq.fr", keys / "server")
    ssh_config(config, known_host, "david", "server.local", keys / "user")
    ssh_config(config, known_host, "ansible", "server.local", keys / "ansible")
    ssh_config(config, known_host, "david", "server.davidlsq.fr", keys / "user")
    ssh_config(config, known_host, "ansible", "server.davidlsq.fr", keys / "ansible")
elif command == "password":
    password = Path(sys.argv[3])
    password_hash(password, output, ["root", "user", "ansible"])
elif command == "image":
    iso = Path(sys.argv[3])
    image_build(iso, "server", output)