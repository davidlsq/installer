#!/usr/bin/env bash

set -e -o pipefail

tarball_nix () {
  revision=$(wget -q -O - https://channels.nixos.org/$1/git-revision | head -c 12)
  name="$1-$revision"
  url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
  url_escape="https:\/\/github.com\/NixOS\/nixpkgs\/archive\/$revision.tar.gz"
  sha256=$(nix-prefetch-url --unpack $url)
  sed -i "s/^    name = \"$1-.*/    name = \"$name\";/g" shell.nix
  sed -i "s/^    url = \".*/    url = \"$url_escape\";/g" shell.nix
  sed -i "s/^    sha256 = \".*/    sha256 = \"$sha256\";/g" shell.nix
}

ansible_replace () {
  sed -i "s/^$1: .*$/$1: $2/g" "$3"
}

ohmyzsh () {
  version=$(curl -s https://api.github.com/repos/ohmyzsh/ohmyzsh/commits | jq -r '.[0].sha')
  ansible_replace ohmyzsh_version $version ansible/roles/ohmyzsh/defaults/main.yml
}

plex () {
  apt-get update
  version=$(apt-cache policy plexmediaserver | grep -F "Candidate:" | awk '{ print $2 }')
  ansible_replace plex_version $version ansible/roles/plex/defaults/main.yml
}

joal () {
  version=$(curl -s https://api.github.com/repos/anthonyraymond/joal/releases | jq -r '.[0].name')
  ansible_replace joal_version $version ansible/roles/joal/defaults/main.yml
}

jackett () {
  version=$(curl -s https://api.github.com/repos/Jackett/Jackett/releases | jq -r '.[0].name' | cut -c 2-)
  ansible_replace jackett_version $version ansible/roles/jackett/defaults/main.yml
}

radarr () {'.[] | select(.prerelease == false)'
  version=$(curl -s https://api.github.com/repos/Radarr/Radarr/releases | jq -r '[.[] | select(.prerelease == false)][0].name')
  ansible_replace servarr_version $version ansible/roles/servarr/vars/radarr.yml
}

tarball_nix nixos-23.05
ohmyzsh
plex
joal
joal
jackett
radarr
