from common import read_yaml, write_yaml
from passlib.apps import custom_app_context


def _hash(value):
    return custom_app_context.hash(value)


def password_hash(src, dest, keys=[]):
    password = read_yaml(src)
    password = password["password"]
    password_hash = {
        key: _hash(value) if key in keys else value for (key, value) in password.items()
    }
    password_hash = {"password": password_hash}
    write_yaml(password_hash, dest)
