let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-23.05-5cfafa12d573";
    url = "https://github.com/NixOS/nixpkgs/archive/5cfafa12d573.tar.gz";
    sha256 = "0996vwrqw1l40k1h7rhq5qfaf50mchilk4ch90k0p7ai8gbbbmz0";
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
      yamllint.files = "^(?!roles).*\\.(yml|yaml)$";
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
