#!/usr/bin/python3

import argparse
import os
import shutil	

from pathlib import Path
from subprocess import DEVNULL, run

def copy(src, dest, mode=None):
    shutil.copy(src, dest)
    if mode is not None:
        run_command(['chmod', mode, str(dest)])

def run_command(command, **kwargs):
    run(command, check=True, stdout=DEVNULL, **kwargs)

def extract_iso_content(iso_path, content_path):
    run_command(['bootstrap/scripts/extract-iso-content.sh', iso_path, content_path])

def extract_iso_efi(iso_path, efi_path):
    run_command(['bootstrap/scripts/extract-iso-efi.sh', iso_path, efi_path])

def create_iso(content_path, efi_path, iso_path):
    run_command(['bootstrap/scripts/create-iso.sh', content_path, efi_path, iso_path], stderr=DEVNULL)

def template(host, src, dest, mode=None):
    run_command([
        'ansible',
        '-i', host + ',',
        '-c', 'local',
        host,
        '-m', 'template',
        '-a', 'src={0} dest={1}'.format(src, dest),
    ], stderr=DEVNULL)
    if mode is not None:
        run_command(['chmod', mode, str(dest)])

parser = argparse.ArgumentParser()
parser.add_argument('--iso', required=True)
parser.add_argument('--host', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args()

host = args.host

root_path    = Path('.')

iso_path     = Path(args.iso)
output_path  = Path(args.output)
tmp_path     = Path(args.output + '.tmp')

files_path   = root_path / 'files'

content_path = tmp_path / 'content'
efi_path     = tmp_path / 'efi.img'

config_path  = content_path / '.config'

shutil.rmtree(tmp_path, ignore_errors=True)
tmp_path.mkdir()

extract_iso_content(iso_path, content_path)
extract_iso_efi(iso_path, efi_path)

config_path.mkdir()

ignore_contents = {
  './bootstrap',
}
def ignore(directory, contents):
    return [
        content for content in contents
        if directory + '/' + content in ignore_contents
    ]
shutil.copytree(root_path, config_path / 'ansible', ignore=ignore)

# Create symlink to kernel
(content_path / 'install').rmdir()
os.symlink(next(content_path.glob('install.*')).name, content_path / 'install')

# Create symlink to grub config
grub_path = content_path / 'boot' / 'grub' / 'grub.cfg'
grub_path.unlink()
os.symlink('../../.config/ansible/files/grub.cfg', grub_path)

# Create symlink to recipe config
os.symlink('ansible/files/' + host + '/recipe', config_path / 'recipe')

# Create preseed config
template(host, 'preseed.cfg.j2', config_path / 'preseed.cfg')

# Create playbook script
template(host, 'playbook.sh.j2', config_path / 'playbook.sh', '+x')

create_iso(content_path, efi_path, output_path)
shutil.rmtree(tmp_path, ignore_errors=True)
