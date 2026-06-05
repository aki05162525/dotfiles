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
      username = "akihiro";

      # ホスト(マシン)ごとに変わる値だけをここで定義する。
      # 共通設定は home-manager/home.nix 側に置く。
      mkHome =
        { system, homeDirectory }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
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
        "${username}@wsl" = mkHome {
          system = "x86_64-linux";
          homeDirectory = "/home/${username}";
        };

        # macOS (Apple Silicon)
        "${username}@mac" = mkHome {
          system = "aarch64-darwin";
          homeDirectory = "/Users/${username}";
        };
      };
    };
}
