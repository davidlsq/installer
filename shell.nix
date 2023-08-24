let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-23.05";
    url = "https://github.com/NixOS/nixpkgs/archive/ddf4688dc7ae.tar.gz";
    sha256 = "1dwa763zp97jymsx2g2xky0yl7gp8nc22yrwf4n3084ahdb149b3";
  };
  pkgs = import nixpkgs { };
  ansible = pkgs.stdenv.mkDerivation {
    name = "ansible";
    propagatedBuildInputs = [ pkgs.python310Packages.passlib ];
    src = pkgs.ansible;
  };
  packages = [
    pkgs.libarchive
    pkgs.xorriso
    pkgs.gnumake
    pkgs.ansible-lint
    pkgs.openssh
    pkgs.gh
    ansible
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
        entry = "python3 -m ansiblelint -v --force-color";
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
