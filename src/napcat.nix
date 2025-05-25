{ pkgs, lib, ... }: let
  sources = pkgs.callPackage ./sources.nix {};
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
in rec {
  patched = pkgs.qq.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ pkgs.unzip ];  # 添加 unzip 到依赖中
    version = "${sources.qq_version}-${sources.napcat_version}";
    inherit src;
    postFixup = ''
      mkdir -p $out/napcat
      unzip ${napcat-shell-zip} -d $out/napcat
      echo "(async () => {await import('/root/napcat/napcat.mjs');})();" > $out/opt/QQ/resources/app/loadNapCat.js
      sed -i 's|"main": "[^"]*"|"main": "./loadNapCat.js"|' $out/opt/QQ/resources/app/package.json
    '';
    meta = {
      description = "Modern protocol-side framework based on NTQQ";
      homepage = "https://github.com/NapNeko/NapCatQQ";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
    };
  });
  program = "${patched}/bin/qq --no-sandbox";
}
