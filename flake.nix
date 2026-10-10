{
  outputs = {
    self, nixpkgs, flake-utils,
  }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: let
    pkgs = import nixpkgs { inherit system; };
    # 默认配置
    defaultConfig = {
      qq_config_dir = "./data/qq";
      nc_config_dir = "./data/napcat/config";
      nc_plugins_dir = "./data/napcat/plugins";
    };
  in rec {
    devShells.default = pkgs.mkShell {};
    lib.buildNapcat = module: pkgs.callPackage ./src {
      config = module;
    };
    packages.default = (lib.buildNapcat defaultConfig).script;
  });
}
