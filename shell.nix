let
  nixpkgs = builtins.fetchTarball {
    name   = "nixos-23.05";
    url    = "https://github.com/NixOS/nixpkgs/archive/ddf4688dc7ae.tar.gz";
    sha256 = "1dwa763zp97jymsx2g2xky0yl7gp8nc22yrwf4n3084ahdb149b3";
  };
  pkgs = import nixpkgs { };
  python = pkgs.python311;
  passlib = pkgs.python311Packages.passlib;
  pipx = pkgs.python311Packages.pipx;

in pkgs.mkShell {
  buildInputs = [
    python
    passlib
    pipx
    pkgs.libarchive
    pkgs.xorriso
    pkgs.gnumake
    pkgs.pre-commit
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
    ANSIBLE_VERSION=2.15.3
    export ANSIBLE_HOME=$ROOT_PATH/.ansible
    pipx install ansible-core==$ANSIBLE_VERSION
    ansible-galaxy collection install ansible.posix community.general

    # install ansible-lint
    ANSIBLE_LINT_VERSION=6.17.2
    echo -e "\033[1;33m\n>>> INSTALLING ANSIBLE-LINT\033[0m"
    pipx install ansible-lint==$ANSIBLE_LINT_VERSION
    pipx inject ansible-lint ansible-core==$ANSIBLE_VERSION

    # install commit hooks
    echo -e "\033[1;33m\n>>> INSTALLING PRE-COMMIT HOOKS\033[0m"
    pre-commit install --overwrite

    # print versions
    echo -e "\033[1;33m\n>>> VERSIONS\033[0m"
    echo python==${python.version}
    echo passlib==${passlib.version}
    echo pipx==${pipx.version}
    echo ansible==$ANSIBLE_VERSION
    echo ansible-lint==$ANSIBLE_LINT_VERSION

    set +eo pipefail
  '';
}
