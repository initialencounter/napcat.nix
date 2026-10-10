{ pkgs, lib, config, ... }: let
  cfg = config;
  pluginsDir = cfg.nc_plugins_dir or "${builtins.dirOf cfg.nc_config_dir}/plugins";
  napcat = pkgs.callPackage ./napcat.nix {};
  fonts = pkgs.makeFontsConf {
    fontDirectories = with pkgs; [ source-han-sans ];
  };
in {
  script = pkgs.writeScriptBin "NapCat" ''
    #!${pkgs.runtimeShell}
    set -eu
    mkdir -p ${lib.escapeShellArg cfg.qq_config_dir} ${lib.escapeShellArg cfg.nc_config_dir} ${lib.escapeShellArg pluginsDir}
    network_args=()
    for variable in http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY; do
      if [[ -v "$variable" ]]; then
        network_args+=(--setenv "$variable" "''${!variable}")
      fi
    done
    for variable in SSL_CERT_FILE SSL_CERT_DIR CURL_CA_BUNDLE NODE_EXTRA_CA_CERTS; do
      if [[ -n "''${!variable-}" ]]; then
        certificate_path=$(${pkgs.coreutils}/bin/realpath -e -- "''${!variable}")
        network_args+=(--ro-bind "$certificate_path" "$certificate_path" --setenv "$variable" "$certificate_path")
      fi
    done
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --unshare-all \
      --share-net \
      --as-pid-1 \
      --uid 0 --gid 0 \
      --clearenv \
      --ro-bind /nix/store /nix/store \
      --ro-bind ${pkgs.tzdata}/share/zoneinfo/Asia/Shanghai /etc/localtime \
      --ro-bind /etc/resolv.conf /etc/resolv.conf \
      --ro-bind /etc/hosts /etc/hosts \
      --ro-bind ${pkgs.cacert}/etc/ssl/certs /etc/ssl/certs \
      --setenv SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt \
      --setenv FONTCONFIG_FILE ${fonts} \
      --bind ${lib.escapeShellArg cfg.nc_config_dir} /root/napcat/config \
      --bind ${lib.escapeShellArg pluginsDir} /root/napcat/plugins \
      --bind ${lib.escapeShellArg cfg.qq_config_dir} /root/.config/QQ \
      --proc /proc \
      --dev /dev \
      --tmpfs /tmp \
      "''${network_args[@]}" \
      ${pkgs.writeScript "sandbox" ''
        #!${pkgs.runtimeShell}
        set -eu

        createService() {
          mkdir -p "/services/$1"
          printf '%s\n' '#!${pkgs.runtimeShell}' "$2" > "/services/$1/run"
          chmod +x "/services/$1/run"
        }

        export PATH=${lib.makeBinPath (with pkgs;
          [ busybox xorg.xorgserver ]
        )}
        export HOME=/root
        export XDG_DATA_HOME=/root/.local/share
        export XDG_CONFIG_HOME=/root/.config
        export TERM=xterm
        mkdir -p /usr/bin /bin
        ln -s "$(command -v env)" /usr/bin/env
        ln -s "$(command -v sh)" /bin/sh

        export DISPLAY=':114'
        createService xvfb 'Xvfb :114 > /dev/null 2>&1'
        for item in ${napcat.patched}/napcat/*; do
          case "''${item##*/}" in
            config|plugins) cp -rn "$item/." "/root/napcat/''${item##*/}/" ;;
            *) cp -r "$item" /root/napcat/ ;;
          esac
        done
        printf -v program_command '%q ' ${napcat.patched}/bin/qq --no-sandbox "$@"
        createService program "exec $program_command"
        exec runsvdir /services
      ''} "$@"
  '';
}
