let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-23.05-55ac2a9d2024";
    url = "https://github.com/NixOS/nixpkgs/archive/55ac2a9d2024.tar.gz";
    sha256 = "1fkbsn8k6xy3p9v74abii8s2prs9gp5hwp7c0zfjhmsgs8wkdv72";
  };
  pkgs = import nixpkgs { };
  python-packages = p: [ p.passlib p.pyyaml p.jinja2 ];
  python = pkgs.python311.withPackages python-packages;
  packages = [
    python
    pkgs.libarchive
    pkgs.xorriso
    pkgs.gnumake
    pkgs.ansible
    pkgs.ansible-lint
    pkgs.openssh
    pkgs.wireguard-tools
    pkgs.gh
  ];
  nix-pre-commit-hooks = import (builtins.fetchTarball
    "https://github.com/cachix/pre-commit-hooks.nix/tarball/master");
  pre-commit-check = nix-pre-commit-hooks.run {
    src = ./.;
    hooks = {
      checkmake.enable = true;
      nixfmt.enable = true;
      black.enable = true;
      isort.enable = true;
      yamllint.enable = true;
      yamllint.files = "^(?!ansible).*\\.(yml|yaml)$";
      ansiblelint = {
        enable = true;
        name = "ansiblelint";
        entry = "ansible-lint -v --force-color";
        language = "python";
        pass_filenames = false;
        files = "^ansible";
        always_run = false;
      };
    };
  };
in pkgs.mkShell {
  packages = packages;
  shellHook = ''
    ${pre-commit-check.shellHook}
  '';
}
