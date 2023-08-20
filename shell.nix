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
    installPhase = "cp -r $src $out";
  };
  buildInputs = with pkgs; [
    pkgs.python311
    pkgs.python311Packages.passlib
    pkgs.libarchive
    pkgs.xorriso
    pkgs.gnumake
    pkgs.pre-commit
    pkgs.nixfmt
    ansible
    pkgs.openssh
    pkgs.gh
  ];
in pkgs.mkShell {
  buildInputs = buildInputs;
  shellHook = ''
    pre-commit install --overwrite
  '';
}
