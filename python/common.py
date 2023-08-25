from os.path import isdir
from shutil import copy as copyfile
from shutil import copytree
from subprocess import check_output

import yaml


def copy(src, dest, mode=None):
    if isdir(src):
        copytree(src, dest)
    else:
        copyfile(src, dest)
    if mode is not None:
        chmod(dest, mode)


def read_yaml(path):
    with path.open("r") as path_stream:
        return yaml.safe_load(path_stream)


def write_yaml(value, path):
    with path.open("w") as path_stream:
        yaml.dump(value, path_stream, sort_keys=False)


def chmod(path, mode):
    if isdir(path):
        check_output(["chmod", "-R", mode, path])
    else:
        check_output(["chmod", mode, path])
