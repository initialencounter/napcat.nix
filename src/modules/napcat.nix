{ config, pkgs, lib, ... }: let
  sources = {
    # Generated by /update.sh - do not update manually!
    # Last updated: 2025-02-07.
    napcat_version = "v4.5.14";
    napcat_url = "https://github.com/NapNeko/NapCatQQ/releases/download/v4.5.14/NapCat.Shell.zip";
    napcat_hash = "sha256-BG7MGFy1kF3O151zdcCD48As4v9cF0oWT5kaj5WSwcw=";
    qq_version = "3.2.15-2025.1.10";
    qq_amd64_url = "https://dldir1.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.15_250110_amd64_01.deb";
    qq_amd64_hash = "sha256-hDfaxxXchdZons8Tb5I7bsd7xEjiKpQrJjxyFnz3Y94=";
    qq_arm64_url = "https://dldir1.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.15_250110_arm64_01.deb";
    qq_arm64_hash = "sha256-F2R5j0x2BnD9/kIsiUe+IbZpAKDOQdjxwOENzzb4RJo=.";
  };
  napcat-shell-zip = pkgs.fetchurl {
    url = sources.napcat_url;
    hash = sources.napcat_hash;
  };

  srcs = {
    x86_64-linux = pkgs.fetchurl {
      url = sources.qq_amd64_url;
      hash = sources.qq_amd64_hash;
    };
    aarch64-linux = pkgs.fetchurl {
      url = sources.qq_arm64_url;
      hash = sources.qq_arm64_hash;
    };
  };

  currentSystem = pkgs.stdenv.hostPlatform.system;
  src = srcs.${currentSystem} or (throw "Unsupported system: ${currentSystem}");
  patched = pkgs.qq.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ pkgs.unzip ];  # 添加 unzip 到依赖中
    version = "3.2.15-2025.1.10";
    inherit src;
    postFixup = ''
      mkdir -p $out/opt/QQ/resources/app/napcat
      unzip ${napcat-shell-zip} -d $out/opt/QQ/resources/app/napcat
      echo "(async () => {await import('/root/napcat/napcat.mjs');})();" > $out/opt/QQ/resources/app/loadNapCat.js
      sed -i 's|"main": "[^"]*"|"main": "./loadNapCat.js"|' $out/opt/QQ/resources/app/package.json
    '';
    meta = {};
  });
in {
  options.napcat = lib.mkOption {
    type = lib.types.path;
    description = "napcat";
  };
  config = {
    sandbox = {
      name = "napcat";
      program = "${patched}/bin/qq --no-sandbox";
      store = patched;
    };
    napcat = config.sandbox.sandbox;
  };
}
