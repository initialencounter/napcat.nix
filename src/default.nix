{ config, pkgs, lib, ... }: let
  sandbox = import ./sandbox.nix { inherit pkgs lib config; };
in {
  inherit (sandbox) script;
} 