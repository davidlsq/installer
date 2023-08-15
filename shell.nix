let
  nixpkgs = builtins.fetchTarball {
    name   = "nixos-23.05";
    url    = "https://github.com/NixOS/nixpkgs/archive/ddf4688dc7ae.tar.gz";
    sha256 = "1dwa763zp97jymsx2g2xky0yl7gp8nc22yrwf4n3084ahdb149b3";
  };
  pkgs = import nixpkgs { };

in pkgs.mkShell {
  buildInputs = [
    pkgs.python311
    pkgs.python311Packages.passlib
    pkgs.python311Packages.pipx
    pkgs.libarchive
    pkgs.xorriso
    pkgs.gnumake
  ];

  shellHook = ''
    set -eo pipefail

    ROOT_PATH="${builtins.toPath ./.}"

    # install pipx
    PIPX_PATH=$ROOT_PATH/.pipx
    export PIPX_HOME=$PIPX_PATH
    export PIPX_BIN_DIR=$PIPX_PATH/bin
    export PATH="$PIPX_BIN_DIR:$PATH"

    # install ansible
    echo -e "\033[1;33m\n>>> INSTALLING ANSIBLE\033[0m"
    export ANSIBLE_HOME=$ROOT_PATH/.ansible
    pipx install ansible-core==2.15.3
    ansible-galaxy collection install ansible.posix community.general

    set +eo pipefail
  '';
}
