#!/usr/bin/python3

import argparse
import os
import shutil
from os.path import exists, realpath
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


def copy_ansible(src, name, dest):
    paths = [
        f"files/{name}",
        f"host_vars/{name}",
        f"roles",
        f"templates/{name}",
        f"{name}.yml",
    ]
    for path in paths:
        _src = f"{src}/{path}"
        _dest = f"{dest}/{path}"
        if exists(_src):
            copy(_src, _dest)


def run_command(command, **kwargs):
    run(command, check=True, stdout=DEVNULL, **kwargs)


def extract_iso_content(iso_path, content_path):
    run_command(["bash/extract-iso-content.sh", iso_path, content_path])


def extract_iso_efi(iso_path, efi_path):
    run_command(["bash/extract-iso-efi.sh", iso_path, efi_path])


def create_iso(content_path, efi_path, iso_path):
    run_command(
        ["bash/create-iso.sh", content_path, efi_path, iso_path],
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
ansible_path = root_path / "ansible"
config_path = root_path / "config"
common_path = config_path / "common"
image_tmp_path = Path(args.output + ".tmp")
image_content_path = image_tmp_path / "content"
image_efi_path = image_tmp_path / "efi.img"
image_config_path = image_content_path / ".config"


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


shutil.rmtree(image_tmp_path, ignore_errors=True)
image_tmp_path.mkdir()

extract_iso_content(iso_path, image_content_path)
extract_iso_efi(iso_path, image_efi_path)

# Copy ansible
image_config_path.mkdir()
copy_ansible(ansible_path, host, image_config_path / "ansible")

# Create symlink to kernel
(image_content_path / "install").rmdir()
os.symlink(
    next(image_content_path.glob("install.*")).name, image_content_path / "install"
)

# Create grub config
copy(common_path / "grub.cfg", image_content_path / "boot" / "grub" / "grub.cfg")

# Copy recipe config
copy(config_path / host / "recipe", image_config_path / "recipe")

# Create preseed config
template(host, common_path / "preseed.cfg.j2", image_config_path / "preseed.cfg")

# Create playbook script
template(host, common_path / "playbook.sh.j2", image_config_path / "playbook.sh", "+x")

# Create install script
copy(common_path / "install.sh", image_config_path / "install.sh", "+x")

# Fix config permissions
run_command(["chmod", "-R", "go-rwx", str(image_config_path)])

create_iso(image_content_path, image_efi_path, output_path)
shutil.rmtree(image_tmp_path, ignore_errors=True)
