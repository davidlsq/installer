from pathlib import Path
from shutil import rmtree

import yaml
from passlib.apps import custom_app_context as pwd_context


class InDir:
    def __init__(self, path, delete_before=True):
        self.path = Path(path)
        self.delete_before = delete_before

    def __enter__(self):
        if self.delete_before:
            rmtree(self.path, ignore_errors=True)
        self.path.mkdir()
        return self

    def __exit__(self, type, value, tb):
        pass

    def __floordiv__(self, name):
        return InDir(self.path / name, False)

    def __truediv__(self, name):
        return self.path / name


def read_yaml(path):
    with open(path, "r") as path_stream:
        return yaml.safe_load(path_stream)


def write_yaml(value, path):
    with open(path, "w") as path_stream:
        yaml.dump(value, path_stream, sort_keys=False)


def password_hash(value):
    return pwd_context.hash(value)
