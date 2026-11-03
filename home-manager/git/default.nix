{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    ignores = [
      "**/.claude/settings.local.json"
      ".DS_Store"
    ];
    # signingkey はマシン固有(1台 = 1キー)のため、ここではなく ~/.gitconfig.local に置く。
    includes = [ { path = "~/.gitconfig.local"; } ];
    settings = {
      user = {
        name = "aki05162525";
        # public リポジトリのコミットに本物のメールを刻まないため GitHub の noreply を使う。
        email = "156570014+aki05162525@users.noreply.github.com";
      };
      core.autocrlf = "input";
      # WSL2 専用: Windows 側 1Password SSH Agent を使うため ssh.exe を呼ぶ。
      # 現状 Linux 構成は WSL2 のみだが、非 WSL の Linux を足す場合はここを見直すこと。
      core.sshCommand = pkgs.lib.mkIf pkgs.stdenv.hostPlatform.isLinux "ssh.exe";
      init.defaultBranch = "main";
      gpg = {
        format = "ssh";
        # 1Password で署名する。WSL2 は WindowsApps の PATH から実行ファイルを探し、
        # ユーザー名を含む絶対パスを避ける。macOS はアプリ同梱のバイナリを使う。
        ssh.program =
          if pkgs.stdenv.hostPlatform.isDarwin then
            "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
          else
            "op-ssh-sign-wsl.exe";
      };
      commit = {
        gpgsign = true;
      };
      push.autoSetupRemote = true;
      fetch.prune = true;
      credential = {
        "https://github.com".helper = [
          ""
          "!gh auth git-credential"
        ];
        "https://gist.github.com".helper = [
          ""
          "!gh auth git-credential"
        ];
      };
    };
  };
}
