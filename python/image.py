import platform
from os import makedirs, symlink
from os.path import exists
from pathlib import Path
from re import escape, match
from shutil import rmtree
from subprocess import DEVNULL, check_output

from common import chmod, copy, read_yaml
from template import render


def _extract_iso_content(iso, content):
    content.mkdir()
    check_output(["bsdtar", "-xf", iso, "-C", content])
    chmod(content, "+w")


def _extract_iso_efi_darwin(iso, efi):
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


def _extract_iso_efi_linux(iso, efi):
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


def _extract_iso_efi(iso, efi):
    system = platform.system()
    if system == "Darwin":
        _extract_iso_efi_darwin(iso, efi)
    elif system == "Linux":
        _extract_iso_efi_linux(iso, efi)
    else:
        raise Exception()


def _symlink_install(content):
    (content / "install").rmdir()
    symlink(next(content.glob("install.*")).name, content / "install")


def _copy_ansible(src, image_name, dest):
    paths = [
        f"files/{image_name}",
        f"host_vars/{image_name}",
        f"roles",
        f"templates/{image_name}",
        f"{image_name}.yml",
    ]
    dest.mkdir()
    for path in paths:
        _src = src / path
        _dest = dest / path
        if exists(_src):
            copy(_src, _dest)


def _create_iso(content, efi, iso):
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


def image_build(iso, image_name, output):
    image_tmp = Path(f"{output}.tmp")
    image_content = image_tmp / "content"
    image_efi = image_tmp / "efi.img"
    image_content_config = image_content / ".config"

    config = Path("config")
    config_common = config / "common"
    config_image = config / image_name

    build = Path("build")
    build_image = build / image_name

    ansible = Path("ansible")

    rmtree(image_tmp, ignore_errors=True)
    image_tmp.mkdir()

    _extract_iso_content(iso, image_content)
    _extract_iso_efi(iso, image_efi)
    _symlink_install(image_content)
    copy(config_common / "grub.cfg", image_content / "boot" / "grub" / "grub.cfg")

    image_content_config.mkdir()
    _copy_ansible(ansible, image_name, image_content_config / "ansible")
    copy(config_image / "recipe", image_content_config / "recipe")
    copy(config_common / "install.sh", image_content_config / "install.sh", "+x")

    variables = {
        **read_yaml(config_image / "image.yml"),
        **read_yaml(build_image / "password.yml"),
        "image_name": image_name,
    }
    render(
        config_common / "preseed.cfg.j2",
        image_content_config / "preseed.cfg",
        variables,
    )
    render(
        config_common / "playbook.sh.j2",
        image_content_config / "playbook.sh",
        variables,
        "+x",
    )
    chmod(image_content_config, "go-rwx")

    _create_iso(image_content, image_efi, output)
    rmtree(image_tmp)
