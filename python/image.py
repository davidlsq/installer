import platform
from os import symlink
from os.path import basename, dirname, exists, isdir
from pathlib import Path
from re import escape, match
from shutil import copy as copyfile
from shutil import copytree, rmtree
from subprocess import DEVNULL, check_output

import yaml
from common import InDir
from jinja2 import Environment, FileSystemLoader, StrictUndefined


def copy(src, dest, mode=None):
    if isdir(src):
        copytree(src, dest)
        if mode is not None:
            check_output(["chmod", "-R", mode, dest])
    else:
        copyfile(src, dest)
        if mode is not None:
            check_output(["chmod", mode, dest])


def copy_ansible(name, dest):
    paths = [
        f"files/{name}",
        f"host_vars/{name}",
        f"roles",
        f"templates/{name}",
        f"{name}.yml",
    ]
    paths = [f"../ansible/{path}" for path in paths]
    paths = [path for path in paths if exists(path)]
    for path in paths:
        copy(path, f"{dest}/{path}")


def extract_iso_content(iso, content):
    check_output(["bsdtar", "-xf", iso, "-C", content])
    check_output(["chmod", "-R", "+w", content])


def extract_iso_efi_darwin(iso, efi):
    output = check_output(["fdisk", iso])
    output = output.decode("utf-8")
    output = output.split("\n")
    output = [
        match(r"\s[0-9]*\:\sEF.*\[\s*([0-9]*)\s*-\s*([0-9]*)\].*$", x) for x in output
    ]
    output = next(iter([x for x in output if x is not None]))
    skip = int(output.group(1))
    count = int(output.group(2))
    check_output(
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
    output = check_output(["fdisk", "-l", iso])
    output = output.decode("utf-8")
    output = output.split("\n")
    output = [
        match(rf"^{escape(str(iso))}[0-9]*\s*([0-9]*)\s*[0-9]*\s*([0-9]*).*EFI.*$", x)
        for x in output
    ]
    output = next(iter([x for x in output if x is not None]))
    skip = int(output.group(1))
    count = int(output.group(2))
    check_output(
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
        raise Exception()


def create_iso(content, efi, iso):
    check_output(
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
        stderr=DEVNULL,
    )


def read_yaml(src):
    with open(src, "r") as src_stream:
        return yaml.safe_load(src_stream)


def get_variables(name):
    return {
        **read_yaml(f"{name}/image.yml"),
        **read_yaml(f"../configure/{name}/password.yml"),
        "name": name,
    }


def render(src, dest, variables, mode=None):
    loader = FileSystemLoader(searchpath=dirname(src))
    env = Environment(loader=loader, undefined=StrictUndefined)
    template = env.get_template(basename(src))
    output = template.render(**variables)
    with open(dest, "w") as dest_stream:
        dest_stream.write(output)
    if mode is not None:
        check_output(["chmod", mode, dest])


class Builder:
    def __init__(self, iso, name, output):
        self.iso = Path(iso)
        self.name = name
        self.output = Path(output)
        self.tmp = Path(f"{self.output}.tmp")

    def __enter__(self):
        with InDir(self.tmp) as tmp:
            extract_iso_efi(self.iso, tmp / "efi.img")
            with tmp // "content" as content:
                extract_iso_content(self.iso, tmp / "content")
                (content / "install").rmdir()
                symlink(next(content.path.glob("install.*")).name, content / "install")
                copy("grub.cfg", content / "boot" / "grub" / "grub.cfg")
                with content // ".config" as config:
                    copy_ansible(self.name, config / "ansible")
                    copy(f"{self.name}/recipe", config / "recipe")
                    copy("install.sh", config / "install.sh", "+x")
                    variables = get_variables(self.name)
                    render("preseed.cfg.j2", config / "preseed.cfg", variables)
                    render("playbook.sh.j2", config / "playbook.sh", variables, "+x")
                    check_output(["chmod", "-R", "go-rwx", config.path])

    def __exit__(self, type, value, tb):
        if tb is None:
            create_iso(self.tmp / "content", self.tmp / "efi.img", self.output)
            # rmtree(self.tmp)
        else:
            raise tb
