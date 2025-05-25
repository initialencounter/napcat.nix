{
  outputs = {
    self, nixpkgs, flake-utils,
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    # 默认配置
    defaultConfig = {
      qq_config_dir = "/root/napcat/config";
      nc_config_dir = "/root/.config/QQ";
    };
  in rec {
    devShells.default = pkgs.mkShell {};
    lib.buildNapcat = module: pkgs.callPackage ./src {
      config = module;
    };
    packages.default = (lib.buildNapcat defaultConfig).script;
  });
}
