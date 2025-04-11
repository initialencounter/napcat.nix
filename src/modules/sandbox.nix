{ config, pkgs, lib, ... }: let
  cfg = config.sandbox;
  fonts = pkgs.makeFontsConf {
    fontDirectories = with pkgs; [ source-han-sans ];
  };
in {
  options.sandbox = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "name of output executable";
    };
    program = lib.mkOption {
      type = lib.types.pathInStore;
      description = "program runs in sandbox";
    };
    store = lib.mkOption {
      type = lib.types.pathInStore;
      description = "napcat path";
    };
    dns = lib.mkOption {
      type = lib.types.str;
      description = "dns server used in sandbox";
      default = "223.5.5.5";
    };
    display = lib.mkOption {
      type = lib.types.int;
      description = "DISPLAY used by Xvfb and x11vnc";
      default = 114;
    };
    sandbox = lib.mkOption {
      type = lib.types.path;
      description = "sandbox";
    };
  };
  config.sandbox.sandbox = pkgs.writeScriptBin cfg.name ''
    #!${pkgs.runtimeShell}
    mkdir -p data
    ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-all \
      --share-net \
      --as-pid-1 \
      --uid 0 --gid 0 \
      --clearenv \
      --ro-bind /nix/store /nix/store \
      --bind ./data /root/napcat/config \
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

        export DISPLAY=':${toString cfg.display}'
        createService xvfb 'Xvfb :${toString cfg.display} > /dev/null 2>&1'
        cp -rf ${cfg.store}/napcat/* /root/napcat/
        createService program "${cfg.program} $@"
        runsvdir /services
      ''} "$@"
  '';
}
