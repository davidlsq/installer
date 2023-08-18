#!/usr/bin/python3

import argparse
import os
import shutil
from os.path import realpath
from pathlib import Path
from subprocess import DEVNULL, run


def copydir(src, dest, mode=None):
    shutil.copytree(src, dest)
    if mode is not None:
        run_command(["chmod", "-R", mode, str(dest)])


def copyfile(src, dest, mode=None):
    shutil.copy(src, dest)
    if mode is not None:
        run_command(["chmod", mode, str(dest)])


def copy(src, dest, mode=None):
    if os.path.isdir(src):
        copydir(src, dest, mode)
    else:
        copyfile(src, dest, mode)


def run_command(command, **kwargs):
    run(command, check=True, stdout=DEVNULL, **kwargs)


def extract_iso_content(iso_path, content_path):
    run_command(["bootstrap/scripts/extract-iso-content.sh", iso_path, content_path])


def extract_iso_efi(iso_path, efi_path):
    run_command(["bootstrap/scripts/extract-iso-efi.sh", iso_path, efi_path])


def create_iso(content_path, efi_path, iso_path):
    run_command(
        ["bootstrap/scripts/create-iso.sh", content_path, efi_path, iso_path],
        stderr=DEVNULL,
    )


parser = argparse.ArgumentParser()
parser.add_argument("--iso", required=True)
parser.add_argument("--host", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

host = args.host

root_path = Path(".")
iso_path = Path(args.iso)
output_path = Path(args.output)
tmp_path = Path(args.output + ".tmp")
ansible_path = root_path / "ansible"
bootstrap_path = root_path / "bootstrap"
templates_path = bootstrap_path / "templates"
files_path = bootstrap_path / "files"
content_path = tmp_path / "content"
efi_path = tmp_path / "efi.img"
config_path = content_path / ".config"


def template(host, src, dest, mode=None):
    run_command(
        [
            "ansible",
            "-i",
            host + ",",
            "-c",
            "local",
            host,
            "-m",
            "template",
            "-a",
            "src={0} dest={1}".format(realpath(src), realpath(dest)),
        ],
        stderr=DEVNULL,
        cwd=str(ansible_path),
    )
    if mode is not None:
        run_command(["chmod", mode, str(dest)])


shutil.rmtree(tmp_path, ignore_errors=True)
tmp_path.mkdir()

extract_iso_content(iso_path, content_path)
extract_iso_efi(iso_path, efi_path)

# Copy ansible
config_path.mkdir()
copy(ansible_path, config_path / "ansible")

# Create symlink to kernel
(content_path / "install").rmdir()
os.symlink(next(content_path.glob("install.*")).name, content_path / "install")

# Create grub config
copy(files_path / "grub.cfg", content_path / "boot" / "grub" / "grub.cfg")

# Copy recipe config
copy(files_path / host / "recipe", config_path / "recipe")

# Create preseed config
template(host, templates_path / "preseed.cfg.j2", config_path / "preseed.cfg")

# Create playbook script
template(host, templates_path / "playbook.sh.j2", config_path / "playbook.sh", "+x")

# Create install script
copy(files_path / "install.sh", config_path / "install.sh", "+x")

# Fix config permissions
run_command(["chmod", "-R", "go-rwx", str(config_path)])

create_iso(content_path, efi_path, output_path)
shutil.rmtree(tmp_path, ignore_errors=True)
