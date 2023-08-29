#!/usr/bin/env bash

set -e -o pipefail

apt-get update

tarball_nix () {
  revision=$(wget -q -O - https://channels.nixos.org/$1/git-revision | head -c 12)
  name="$1-$revision"
  url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
  sha256=$(nix-prefetch-url --unpack $url)
  cat > "$2" << EOF
{
  name = "$name";
  url = "$url";
  sha256 = "$sha256";
}
EOF
}

plex () {
  version=$(apt-cache policy plexmediaserver | grep -F "Candidate:" | awk '{ print $2 }')
  echo "$version"
}

rm -rf versions
mkdir -p versions

tarball_nix nixos-23.05 versions/tarball.nix

cat > versions/ansible.yml << EOF
---

plex_version: $(plex)
EOF
