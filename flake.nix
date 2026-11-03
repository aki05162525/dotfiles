{
  description = "Home Manager configuration of akihiro";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      herdr,
      ...
    }:
    let
      # ホスト(マシン)ごとに変わる値(OS と username)だけを渡す。
      # homeDirectory は OS と username から自動で組み立てる。
      # 共通設定は home-manager/home.nix 側に置く。
      mkHome =
        { system, username }:
        let
          isDarwin = nixpkgs.lib.hasSuffix "darwin" system;
          homeDirectory = (if isDarwin then "/Users/" else "/home/") + username;
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "1password-cli"
              ];
          };
          modules = [
            ./home-manager/home.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.packages = [ herdr.packages.${system}.default ];
            }
          ];
        };
    in
    {
      homeConfigurations = {
        # WSL2 (Ubuntu) on Windows
        "akihiro@wsl" = mkHome {
          system = "x86_64-linux";
          username = "akihiro";
        };

        # macOS (Apple Silicon)
        "takagi@mac" = mkHome {
          system = "aarch64-darwin";
          username = "takagi";
        };
      };

      # homeConfigurations だけでは flake check がビルドしないため、
      # activationPackage を checks に登録する。実行中の OS 向け構成を検証する。
      # 重い検証なので push hook にはせず、更新後などに手動で実行する。
      checks = {
        x86_64-linux.home-manager = self.homeConfigurations."akihiro@wsl".activationPackage;
        aarch64-darwin.home-manager = self.homeConfigurations."takagi@mac".activationPackage;
      };

      # nixfmt-tree でリポジトリを再帰整形する。
      # nixfmt を直接指定すると、無引数の nix fmt が stdin 待ちになる。
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
      };
    };
}
