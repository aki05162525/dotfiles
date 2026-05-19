{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    shellAliases = {
      zj = "zellij";
      ll = "ls -la";
      g = "git";
    };
    envExtra = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';
    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];
  };
}
