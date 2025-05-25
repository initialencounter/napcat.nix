{ pkgs, lib, config, ... }: let
  cfg = config;
  napcat = pkgs.callPackage ./napcat.nix {};
  fonts = pkgs.makeFontsConf {
    fontDirectories = with pkgs; [ source-han-sans ];
  };
in {
  script = pkgs.writeScriptBin "NapCat" ''
    #!${pkgs.runtimeShell}
    mkdir -p ${cfg.qq_config_dir} ${cfg.nc_config_dir}
    ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-all \
      --share-net \
      --as-pid-1 \
      --uid 0 --gid 0 \
      --clearenv \
      --ro-bind /nix/store /nix/store \
      --ro-bind ${pkgs.tzdata}/share/zoneinfo/Asia/Shanghai /etc/localtime \
      --bind ${cfg.nc_config_dir} /root/napcat/config \
      --bind ${cfg.qq_config_dir} /root/.config/QQ \
      --proc /proc \
      --dev /dev \
      --tmpfs /tmp \
      ${pkgs.writeScript "sandbox" ''
        #!${pkgs.runtimeShell}

        createService() {
          mkdir -p /services/$1
          echo -e "#!${pkgs.runtimeShell}\n$2" > /services/$1/run
          chmod +x /services/$1/run
        }

        export PATH=${lib.makeBinPath (with pkgs;
          [ busybox xorg.xorgserver ]
        )}
        export HOME=/root
        export XDG_DATA_HOME=/root/.local/share
        export XDG_CONFIG_HOME=/root/.config
        export TERM=xterm
        mkdir -p /usr/bin /bin
        ln -s $(which env) /usr/bin/env
        ln -s $(which sh) /bin/sh

        export DISPLAY=':114'
        createService xvfb 'Xvfb :114 > /dev/null 2>&1'
        cp -rf ${napcat.patched}/napcat/* /root/napcat/
        createService program "${napcat.program} $@"
        runsvdir /services
      ''} "$@"
  '';
}
