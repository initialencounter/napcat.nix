# napcat.nix

Fork from [chronocat.nix](https://github.com/Anillc/chronocat.nix)

配置文件目录 ./data/napcat/config

# 使用方法

## install nix

[NixOS](https://nixos.org/download/)

```shell
sh <(curl -L https://nixos.org/nix/install) --daemon
```

## setup

```shell
mkdir -p ~/.config/nix && touch ~/.config/nix/nix.conf
vi ~/.config/nix/nix.conf
# 写入
experimental-features = nix-command
```

```shell
nix flake update  --extra-experimental-features flakes
nix build --extra-experimental-features flakes
nix run --extra-experimental-features flakes
```