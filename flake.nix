{
  description = "Home Manager configuration of akihiro";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
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

      # `nix fmt` で使うフォーマッタ。各マシンの system 分を定義する。
      # nixfmt は公式フォーマッタ(旧 nixfmt-rfc-style と同一)。
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
      };
    };
}
