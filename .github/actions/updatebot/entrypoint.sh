#!/usr/bin/env bash

set -e -o pipefail

tarball_nix () {
  revision=$(wget -q -O - https://channels.nixos.org/$1/git-revision | head -c 12)
  name="$1-$revision"
  url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
  sha256=$(nix-prefetch-url --unpack $url)
  cat > versions/tarball.nix << EOF
{
  name = "$name";
  url = "$url";
  sha256 = "$sha256";
}
EOF
}

ansible_replace () {
  sed -i "s/^$1: .*$/$1: $2/g" versions/ansible.yml
}

ohmyzsh () {
  version=$(curl -s https://api.github.com/repos/ohmyzsh/ohmyzsh/commits | jq -r '.[0].sha')
  ansible_replace ohmyzsh_version $version
}

plex () {
  apt-get update
  version=$(apt-cache policy plexmediaserver | grep -F "Candidate:" | awk '{ print $2 }')
  ansible_replace plex_version $version
}

joal () {
  version=$(curl -s https://api.github.com/repos/anthonyraymond/joal/releases | jq -r '.[0].name')
  ansible_replace joal_version $version
}

jackett () {
  version=$(curl -s https://api.github.com/repos/Jackett/Jackett/releases | jq -r '.[0].name' | cut -c 2-)
  ansible_replace jackett_version $version
}

case "$1" in
  tarball_nix)
    tarball_nix nixos-23.05
    ;;
  ohmyzsh)
    ohmyzsh
    ;;
  plex)
    plex
    ;;
  joal)
    joal
    ;;
  jackett)
    jackett
    ;;
esac
