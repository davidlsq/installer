import os
import pathlib
import platform
import re
import shutil
import subprocess

import jinja2
import yaml
from passlib.apps import custom_app_context as pwd_context


def copydir(src, dest, mode=None):
    shutil.copytree(src, dest)
    if mode is not None:
        subprocess.run(["chmod", "-R", mode, dest])


def copyfile(src, dest, mode=None):
    shutil.copy(src, dest)
    if mode is not None:
        subprocess.run(["chmod", mode, dest])


def copy(src, dest, mode=None):
    if os.path.isdir(src):
        copydir(src, dest, mode)
    else:
        copyfile(src, dest, mode)


def read_yaml(src):
    with src.open("r") as src_stream:
        return yaml.safe_load(src_stream)


def password_hash(value):
    return pwd_context.hash(value)


def extract_iso_content(iso, content):
    content.mkdir()
    subprocess.run(["bsdtar", "-xf", iso, "-C", content])
    subprocess.run(["chmod", "-R", "+w", content])


def extract_iso_efi_darwin(iso, efi):
    output = subprocess.check_output(["fdisk", iso])
    output = output.decode("utf-8")
    output = output.split("\n")
    output = [
        re.match(r"\s[0-9]*\:\sEF.*\[\s*([0-9]*)\s*-\s*([0-9]*)\].*$", x)
        for x in output
    ]
    output = next(iter([x for x in output if x is not None]))
    skip = int(output.group(1))
    count = int(output.group(2))
    subprocess.run(
        [
            "dd",
            f"if={iso}",
            f"of={efi}",
            f"skip={skip}",
            f"count={count}",
            "status=none",
        ]
    )


def extract_iso_efi_linux(iso, efi):
    output = subprocess.check_output(["fdisk", "-l", iso])
    output = output.decode("utf-8")
    output = output.split("\n")
    output = [
        re.match(
            rf"^{re.escape(str(iso))}[0-9]*\s*([0-9]*)\s*[0-9]*\s*([0-9]*).*EFI.*$", x
        )
        for x in output
    ]
    output = next(iter([x for x in output if x is not None]))
    skip = int(output.group(1))
    count = int(output.group(2))
    subprocess.run(
        [
            "dd",
            f"if={iso}",
            f"of={efi}",
            f"skip={skip}",
            f"count={count}",
            "status=none",
        ]
    )


def extract_iso_efi(iso, efi):
    system = platform.system()
    if system == "Darwin":
        extract_iso_efi_darwin(iso, efi)
    elif system == "Linux":
        extract_iso_efi_linux(iso, efi)
    else:
        exit(1)


def create_iso(content, efi, iso):
    subprocess.run(
        [
            "xorriso",
            "-as",
            "mkisofs",
            "-quiet",
            "-V",
            "CDROM",
            "-R",
            "-uid",
            "0",
            "-gid",
            "0",
            "-e",
            "boot/grub/efi.img",
            "-no-emul-boot",
            "-append_partition",
            "2",
            "0xef",
            f"{efi}",
            "-partition_cyl_align",
            "all",
            "-o",
            f"{iso}",
            f"{content}",
        ],
        stderr=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
    )


def template(src, dest, variables, mode=None):
    loader = jinja2.FileSystemLoader(searchpath="./")
    env = jinja2.Environment(loader=loader, undefined=jinja2.StrictUndefined)
    env.filters["password_hash"] = password_hash
    template = env.get_template(str(src))
    output = template.render(**variables)
    with dest.open("w") as dest_stream:
        dest_stream.write(output)


class BuilderPath:
    def __init__(self, iso, image, output):
        root = pathlib.Path(".")
        self.bootstrap = root / "bootstrap"
        self.ansible = root / "ansible"
        self.config = self.bootstrap / "config"
        self.config_image = self.config / image

        self.iso = self.bootstrap / iso
        self.output = self.bootstrap / output
        self.build = self.bootstrap / (output + ".tmp")
        self.build_content = self.build / "content"
        self.build_efi = self.build / "efi.img"
        self.build_config = self.build_content / ".config"


class Builder:
    def __init__(self, iso, name, output):
        self.path = BuilderPath(iso, name, output)

    def __enter__(self):
        shutil.rmtree(self.path.build, ignore_errors=True)
        self.path.build.mkdir()
        extract_iso_content(self.path.iso, self.path.build_content)
        extract_iso_efi(self.path.iso, self.path.build_efi)

        # Copy ansible
        self.path.build_config.mkdir()
        copy(self.path.ansible, self.path.build_config / "ansible")
        # Create symlink to kernel
        (self.path.build_content / "install").rmdir()
        os.symlink(
            next(self.path.build_content.glob("install.*")).name,
            self.path.build_content / "install",
        )
        # Create grub config
        copy(
            self.path.config / "grub.cfg",
            self.path.build_content / "boot" / "grub" / "grub.cfg",
        )
        # Copy recipe config
        copy(self.path.config_image / "recipe", self.path.build_config / "recipe")
        # Load variables
        variables = {
            "bootstrap": read_yaml(self.path.config_image / "bootstrap.yml"),
            "password": read_yaml(self.path.config_image / "password.yml"),
        }
        # Create preseed config
        template(
            self.path.config / "preseed.cfg.j2",
            self.path.build_config / "preseed.cfg",
            variables,
        )
        # Create playbook script
        template(
            self.path.config / "playbook.sh.j2",
            self.path.build_config / "playbook.sh",
            variables,
            "+x",
        )
        # Create install script
        copy(
            self.path.config / "install.sh", self.path.build_config / "install.sh", "+x"
        )
        # Fix config permissions
        subprocess.run(["chmod", "-R", "go-rwx", self.path.build_config])

    def __exit__(self, type, value, tb):
        if tb is None:
            create_iso(self.path.build_content, self.path.build_efi, self.path.output)
            shutil.rmtree(self.path.build)
        else:
            raise tb
