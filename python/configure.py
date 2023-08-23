from pathlib import Path
from subprocess import check_output


def ssh_keygen(key):
    output = check_output(
        ["ssh-keygen", "-C", "", "-N", "", "-t", "ed25519", "-f", key],
    )


def ssh_known_host(known_host, host, key):
    with Path(f"{key}.pub").open("r") as key_pub_stream:
        key_pub = key_pub_stream.read()
    with known_host.open("a") as known_host_stream:
        known_host_stream.write(f"{host} {key_pub}")


def ssh_config(config, known_host, user, host, key):
    with Path(config).open("a") as config_stream:
        config_stream.write(f"Math user {user} host {host}\n")
        config_stream.write(f"  IdentitiesOnly yes\n")
        config_stream.write(f"  GlobalKnownHostsFile {known_host.resolve()}\n")
        config_stream.write(f"  IdentityFile {key.resolve()}\n")
