{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
    };
    shellAliases = {
      ll = "ls -la";
      g = "git";
    };
    initContent = ''
      if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
        function _wezterm_osc7_pwd() {
          printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
        }
        precmd_functions+=(_wezterm_osc7_pwd)
      fi

      function hms() {
        if [[ "$(uname)" == "Darwin" ]]; then
          home-manager switch --flake .#takagi@mac
        else
          home-manager switch --flake .#akihiro@wsl
        fi
      }
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
