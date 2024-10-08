{ config, pkgs, lib, ... }: let
  sources = {
    # Generated by /update.sh - do not update manually!
    # Last updated: 2024-10-02.
    napcat_version = "v2.6.23";
    napcat_url = "https://github.com/NapNeko/NapCatQQ/releases/download/v2.6.23/NapCat.Shell.zip";
    napcat_hash = "sha256-am31iewbX/Uk6pnDrTlRoDCvUWRtQ+5dWIwTJGaGMxU=";
    qq_version = "3.2.12-2024.9.27";
    qq_amd64_url = "https://dldir1.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.12_240927_amd64_01.deb";
    qq_amd64_hash = "sha256-xBGSSxXDu+qUwj203i3iAkfI97iLtGOuGMGfEU6kCyQ=";
    qq_arm64_url = "https://dldir1.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.12_240927_arm64_01.deb";
    qq_arm64_hash = "sha256-VfM+p2cTNkDZc7sTftfTuRSMKVWwE6TerW25pA1MIR0=";
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
    version = "3.2.12-2024.9.27";
    inherit src;
    postFixup = ''
      mkdir -p $out/opt/QQ/resources/app/napcat
      unzip ${napcat-shell-zip} -d $out/opt/QQ/resources/app/napcat
      rm -rf $out/opt/QQ/resources/app/package.json
      mv $out/opt/QQ/resources/app/napcat/qqnt.json $out/opt/QQ/resources/app/package.json
      echo "(async () => {await import('/root/napcat/napcat.mjs');})();" > $out/opt/QQ/resources/app/loadNapCat.js
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