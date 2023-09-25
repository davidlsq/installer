from pathlib import Path
from subprocess import check_output


def wg_keygen(key):
    key_bytes = check_output(["wg", "genkey"])
    key_pub_bytes = check_output(["wg", "pubkey"], input=key_bytes)
    with key.open("wb") as key_stream:
        key_stream.write(key_bytes)
    with open(str(key) + ".pub", "wb") as key_pub_stream:
        key_pub_stream.write(key_pub_bytes)


def wg_client(server_key_pub, peer_key, address, port, domain, dns, config):
    with config.open("w") as config_stream:
        config_stream.write(f"[Interface]\n")
        config_stream.write(f"Address = {address}\n")
        config_stream.write(f"ListenPort = {port}\n")
        config_stream.write(f"PrivateKey = {read_key(peer_key)}")
        config_stream.write(f"DNS = {dns}\n")
        config_stream.write(f"[Peer]\n")
        config_stream.write(f"PublicKey = {read_key(server_key_pub)}")
        config_stream.write(f"AllowedIPs = 0.0.0.0/0, ::/0\n")
        config_stream.write(f"Endpoint = {domain}:{port}\n")


def read_key(key):
    with key.open("r") as key_stream:
        return key_stream.readlines()[0]
