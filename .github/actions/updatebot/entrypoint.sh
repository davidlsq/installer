#!/usr/bin/env bash

set -x -e -o pipefail

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

apt_release () {
  apt-get update -qq
  apt-cache policy $1 | grep -F "Candidate:" | awk '{ print $2 }'
}

ansible_replace () {
  sed -i "s/^$1: .*$/$1: $2/g" "$3"
}

github_commit () {
  curl -s "https://api.github.com/repos/$1/commits" | jq -r '.[0].sha'
}

github_release () {
  curl -s "https://api.github.com/repos/$1/releases" | jq -r '[.[] | select(.prerelease == false)][0].name'
}

ohmyzsh () {
  version=$(github_commit ohmyzsh/ohmyzsh)
  ansible_replace ohmyzsh_version $version ansible/roles/ohmyzsh/defaults/main.yml
}

plex () {
  version=$(apt_release plexmediaserver)
  ansible_replace plex_version $version ansible/roles/plex/defaults/main.yml
}

joal () {
  version=$(github_release anthonyraymond/joal)
  ansible_replace joal_version $version ansible/roles/joal/defaults/main.yml
}

jackett () {
  version=$(github_release Jackett/Jackett)
  ansible_replace jackett_version $version ansible/roles/jackett/defaults/main.yml
}

radarr () {
  version=$(github_release Radarr/Radarr)
  ansible_replace servarr_version $version ansible/roles/servarr/vars/radarr.yml
}

tarball_nix nixos-23.05
ohmyzsh
plex
joal
joal
jackett
radarr
