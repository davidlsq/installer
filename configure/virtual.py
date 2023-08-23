#!/usr/bin/env python3 -B

import shutil
from pathlib import Path
from shutil import rmtree

from common import InDir, password_hash, read_yaml, write_yaml

from configure import ssh_config, ssh_keygen, ssh_known_host

with InDir("virtual") as virtual:
    with virtual // "ssh" as ssh:
        with ssh // "keys" as keys:
            keys_host = keys / "server"
            keys_user = keys / "user"
            keys_ansible = keys / "ansible"
            ssh_keygen(keys_host)
            ssh_keygen(keys / "user")
            ssh_keygen(keys / "ansible")
        known_host = ssh / "known_host"
        private_host = "virtual.local"
        ssh_known_host(known_host, private_host, keys_host)
        config = ssh / "config"
        ssh_config(config, known_host, "david", private_host, keys_user)
        ssh_config(config, known_host, "ansible", private_host, keys_ansible)
    password_clear = read_yaml("../image/virtual/password.yml")["password"]
    password_safe = {
        "password": {
            "root": password_hash(password_clear["root"]),
            "user": password_hash(password_clear["user"]),
            "ansible": password_hash(password_clear["ansible"]),
        }
    }
    write_yaml(password_safe, virtual / "password.yml")
