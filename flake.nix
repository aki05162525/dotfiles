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
      # ===== マシンごとに変わる値はここ =====
      username = "akihiro";
      homeDirectory = "/home/${username}";
      system = "x86_64-linux";
      # ====================================

      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager/home.nix
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
          }
        ];
      };
    };
}
