let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-23.05-679cadfdfed2";
    url = "https://github.com/NixOS/nixpkgs/archive/679cadfdfed2.tar.gz";
    sha256 = "05iybhlry8sg6qdgf7qx1d8rvq43ph32qgpar53g8yja300x0swz";
  };
  pkgs = import nixpkgs { };
  python-packages = p: [ p.ansible-core p.passlib ];
  python = pkgs.python311.withPackages python-packages;
  packages = [
    python
    pkgs.libarchive
    pkgs.xorriso
    pkgs.gnumake
    pkgs.ansible-lint
    pkgs.gitleaks
    pkgs.openssh
    pkgs.rsync
    pkgs.wireguard-tools
    pkgs.bitwarden-cli
    pkgs.gh
  ];
  nix-pre-commit-hooks = import (builtins.fetchTarball
    "https://github.com/cachix/pre-commit-hooks.nix/tarball/master");
  pre-commit-check = nix-pre-commit-hooks.run {
    src = ./.;
    hooks = {
      isort.enable = true;
      black.enable = true;
      checkmake.enable = true;
      nixfmt.enable = true;
      yamllint.enable = true;
      yamllint.files = "^\\.github.*\\.(yml|yaml)$";
      ansiblelint = {
        enable = true;
        name = "ansiblelint";
        entry = "ansible-lint -v --force-color";
        language = "python";
        pass_filenames = false;
        always_run = false;
      };
      gitleaks = {
        enable = true;
        name = "gitleaks";
        entry = "gitleaks protect --verbose --redact --staged";
        language = "golang";
        pass_filenames = false;
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
