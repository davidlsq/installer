let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-23.05";
    url = "https://github.com/NixOS/nixpkgs/archive/ddf4688dc7ae.tar.gz";
    sha256 = "1dwa763zp97jymsx2g2xky0yl7gp8nc22yrwf4n3084ahdb149b3";
  };
  pkgs = import nixpkgs { };
  python = pkgs.python311;
  pipx = pkgs.python311Packages.pipx;
  libarchive = pkgs.libarchive;
  xorriso = pkgs.xorriso;
  gnumake = pkgs.gnumake;

  nix-pre-commit-hooks = import (builtins.fetchTarball
    "https://github.com/cachix/pre-commit-hooks.nix/tarball/master");
  pre-commit-check = nix-pre-commit-hooks.run {
    src = ./.;
    hooks = {
      checkmake.enable = true;
      nixfmt.enable = true;
      black.enable = true;
      isort.enable = true;
      ansiblelint = {
        enable = true;
        name = "ansiblelint";
        entry = "ansible-lint -v --force-color";
        language = "system";
        pass_filenames = true;
        always_run = false;
        types = [ "file" ];
        files = "^(host_vars|inventory|roles|templates|(server|virtual)\\.yml)";
      };
      versions = {
        enable = true;
        name = "versions";
        entry = ''nix-shell --command "print_versions > versions"'';
        language = "system";
        pass_filenames = false;
        always_run = false;
        types = [ "file" ];
        files = "^(shell\\.nix|versions)$";
      };
    };
  };

in pkgs.mkShell {
  buildInputs = [ python pipx libarchive xorriso gnumake ];

  shellHook = ''
    set -eo pipefail

    ROOT_PATH="${builtins.toPath ./.}"

    ANSIBLE_VERSION=2.15.3
    ANSIBLE_LINT_VERSION=6.17.2
    PASSLIB_VERSION=1.7.4

    # print versions
    print_versions () {
      echo PYTHON_VERSION=${python.version}
      echo PASSLIB_VERSION=$PASSLIB_VERSION
      echo PIPX_VERSION=${pipx.version}
      echo ANSIBLE_VERSION=$ANSIBLE_VERSION
      echo ANSIBLE_LINT_VERSION=$ANSIBLE_LINT_VERSION
      echo LIBARCHIVE_VERSION=${libarchive.version}
      echo XORRISO_VERSION=${xorriso.version}
      echo GNUMAKE_VERSION=${gnumake.version}
    }
    echo -e "\033[1;33m\n>>> PRINT VERSIONS\033[0m"
    export $(print_versions | xargs)
    print_versions

    # install pipx
    PIPX_PATH=$ROOT_PATH/.pipx
    export PIPX_HOME=$PIPX_PATH
    export PIPX_BIN_DIR=$PIPX_PATH/bin
    export PATH="$PIPX_BIN_DIR:$PATH"

    # install ansible
    echo -e "\033[1;33m\n>>> INSTALLING ANSIBLE\033[0m"
    export ANSIBLE_HOME=$ROOT_PATH/.ansible
    pipx install ansible-core==$ANSIBLE_VERSION
    pipx inject ansible-core passlib==$PASSLIB_VERSION
    ansible-galaxy collection install ansible.posix community.general

    # install ansible-lint
    echo -e "\033[1;33m\n>>> INSTALLING ANSIBLE-LINT\033[0m"
    pipx install ansible-lint==$ANSIBLE_LINT_VERSION
    pipx inject ansible-lint ansible-core==$ANSIBLE_VERSION
    pipx inject ansible-lint passlib==$PASSLIB_VERSION

    # install commit hooks
    echo -e "\033[1;33m\n>>> INSTALLING PRE-COMMIT HOOKS\033[0m"
    ${pre-commit-check.shellHook}

    set +eo pipefail
  '';
}
