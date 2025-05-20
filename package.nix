{
  lib,
  qq,
  xorg,
  fetchzip,
  busybox,
  tzdata,
  bubblewrap,
  runtimeShell,
  writeScript,
  writeScriptBin,
}: let
    napcat_version = "v4.7.65";
    napcat-src = fetchzip {
      url = "https://github.com/NapNeko/NapCatQQ/releases/download/${napcat_version}/NapCat.Shell.zip";
      hash = "sha256-8VdtixmMXoFur4wNzmmPfYZqJZ5TrzArKhwca3FJ4x8=";
      stripRoot = false;
    };
    napcat-qq = qq.overrideAttrs (
      old: {
        version = "${old.version}-NapCat-${napcat_version}";
        postFixup = ''
          cp -r ${napcat-src} $out/napcat
          chmod -R u+w $out/napcat
          echo "(async () => {await import('/napcat/napcat.mjs');})();" > $out/opt/QQ/resources/app/loadNapCat.js
          sed -i 's|"main": "[^"]*"|"main": "./loadNapCat.js"|' $out/opt/QQ/resources/app/package.json
        '';
        meta = {};
    });
in writeScriptBin "napcat" ''
  #!${runtimeShell}
  if [ "$#" -eq 0 ]; then
    echo usage: napcat [ -q qq_uin ] config
    echo "  config/napcat: map to napcat config directory"
    echo "  config/qq:     map to $HOME/.config/QQ"
    echo "  config/log:     napcat logs"
    exit 1
  fi
  NAPCATQQ_DATADIR="''${!#}"
  set -- "''${@:1:$(($# - 1))}"
  if ! [ -d "$NAPCATQQ_DATADIR" ]; then
    echo no such directory: $NAPCATQQ_DATADIR
    exit 1
  fi
  for dir in napcat qq log; do
    p=$NAPCATQQ_DATADIR/$dir
    if ! [ -d "$p" ]; then
      mkdir "$p"
    fi
  done
  ${bubblewrap}/bin/bwrap \
    --unshare-all \
    --share-net \
    --as-pid-1 \
    --uid 0 --gid 0 \
    --clearenv \
    --ro-bind /nix/store /nix/store \
    --ro-bind ${tzdata}/share/zoneinfo/Asia/Shanghai /etc/localtime \
    --bind $NAPCATQQ_DATADIR/napcat /root/napcat/config \
    --bind $NAPCATQQ_DATADIR/qq /root/.config/QQ \
    --bind $NAPCATQQ_DATADIR/log /napcat/logs \
    --proc /proc \
    --dev /dev \
    --tmpfs /tmp \
    ${writeScript "sandbox" ''
      #!${runtimeShell}

      createService() {
        mkdir -p /services/$1
        echo -e "#!${runtimeShell}\n$2" > /services/$1/run
        chmod +x /services/$1/run
      }

      export PATH=${lib.makeBinPath [ busybox xorg.xorgserver ]}
      export HOME=/root
      export XDG_DATA_HOME=/root/.local/share
      export XDG_CONFIG_HOME=/root/.config
      export TERM=xterm
      mkdir -p /usr/bin /bin
      ln -s $(which env) /usr/bin/env
      ln -s $(which sh) /bin/sh

      export DISPLAY=':1'
      createService xvfb 'Xvfb :1 > /dev/null 2>&1'

      cp -rf ${napcat-qq}/napcat/* /napcat/
      createService program "${napcat-qq}/bin/qq --no-sandbox $@"
      runsvdir /services
    ''} "$@"
''