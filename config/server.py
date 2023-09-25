#!/usr/bin/env -S python3 -B

import sys
from pathlib import Path

from common import read_yaml, write_yaml
from image import image_build
from password import hash, sha256
from ssh import ssh_config, ssh_keygen, ssh_known_host
from wg import wg_client, wg_keygen

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
elif command == "wg":
    output.mkdir()
    wg_keygen(output / "server")
    wg_keygen(output / "peer-1")
    wg_keygen(output / "peer-2")
    wg_client(
        server_key_pub=Path(str(output / "server") + ".pub"),
        peer_key=output / "peer-1",
        address="192.168.1.2/24",
        port=51820,
        domain="server.davidlsq.fr",
        dns="192.168.0.2",
        config=output / "peer-1.conf",
    )
    wg_client(
        server_key_pub=Path(str(output / "server") + ".pub"),
        peer_key=output / "peer-2",
        address="192.168.1.3/24",
        port=51820,
        domain="server.davidlsq.fr",
        dns="192.168.0.2",
        config=output / "peer-2.conf",
    )
elif command == "password":
    passwords = read_yaml(Path(sys.argv[3]))["password"]
    passwords_hash = {
        **passwords,
        "root": hash(passwords["root"]),
        "user": hash(passwords["user"]),
        "ansible": hash(passwords["ansible"]),
        "pihole": sha256(sha256(passwords["pihole"])),
    }
    write_yaml({"password": passwords_hash}, output)
elif command == "image":
    iso = Path(sys.argv[3])
    image_build(iso, "server", output)
