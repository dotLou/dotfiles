{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz") {} }:

pkgs.buildEnv {
  name = "dotlou-tools";
  paths = with pkgs; [
    claude-code
  ];
}