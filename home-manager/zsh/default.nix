{ ... }:

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
  };
}
