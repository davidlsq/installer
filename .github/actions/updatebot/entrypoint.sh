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
  ansible_replace ohmyzsh_version $version roles/ohmyzsh/defaults/main.yml
}

plex () {
  version=$(apt_release plexmediaserver)
  ansible_replace plex_version $version roles/plex/defaults/main.yml
}

qbittorrent () {
  version=$(apt_release qbittorrent-nox)
  ansible_replace qbittorrent_version $version roles/qbittorrent/defaults/main.yml
}

joal () {
  version=$(github_release anthonyraymond/joal)
  ansible_replace joal_version $version roles/joal/defaults/main.yml
}

sabnzbd () {
  version=$(github_release sabnzbd/sabnzbd | cut -d ' ' -f 2)
  ansible_replace sabnzbd_version $version roles/sabnzbd/defaults/main.yml
}

jackett () {
  version=$(github_release Jackett/Jackett | cut -c 2-)
  ansible_replace jackett_version $version roles/jackett/defaults/main.yml
}

prowlarr () {
  version=$(github_release Prowlarr/Prowlarr)
  ansible_replace servarr_version $version roles/servarr/vars/prowlarr.yml
}

radarr () {
  version=$(github_release Radarr/Radarr)
  ansible_replace servarr_version $version roles/servarr/vars/radarr.yml
}

sonarr () {
  version=$(curl -s https://services.sonarr.tv/v1/download/main | jq -r '.version')
  ansible_replace servarr_version $version roles/sonarr/defaults/main.yml
}

tarball_nix nixos-23.05
ohmyzsh
plex
qbittorrent
joal
sabnzbd
jackett
prowlarr
radarr
sonarr
