{ config, pkgs, lib, ... }: let
  napcat-shell-zip = pkgs.fetchurl {
    url = "https://github.com/NapNeko/NapCatQQ/releases/download/v2.6.16/NapCat.Shell.zip";
    hash = "sha256-UxsDe2zbMZioIinH6wErBrK5SI6QuOGJaIRJI0r5gxU=";
  };

  patched = pkgs.qq.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ pkgs.unzip ];  # 添加 unzip 到依赖中
    version = "3.2.12-2024.9.27";
    src = pkgs.fetchurl {
      url = "https://dldir1.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.12_240927_amd64_01.deb";
      hash = "sha256-xBGSSxXDu+qUwj203i3iAkfI97iLtGOuGMGfEU6kCyQ=";
    };
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