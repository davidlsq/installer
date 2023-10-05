let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-23.05-8a4c17493e5c";
    url = "https://github.com/NixOS/nixpkgs/archive/8a4c17493e5c.tar.gz";
    sha256 = "0pd8n09jnpghzc3v97h7pdsk22piiv0f30blyk9jrjibdpf03pw2";
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
    pkgs.openssh
    pkgs.wireguard-tools
    pkgs.bitwarden-cli
    pkgs.gh
  ];
  nix-pre-commit-hooks = import (builtins.fetchTarball
    "https://github.com/cachix/pre-commit-hooks.nix/tarball/master");
  pre-commit-check = nix-pre-commit-hooks.run {
    src = ./.;
    hooks = {
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
    };
  };
in pkgs.mkShell {
  packages = packages;
  shellHook = ''
    ${pre-commit-check.shellHook}
  '';
}
