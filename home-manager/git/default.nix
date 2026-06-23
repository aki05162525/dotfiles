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
        email = "akihiro05162525@gmail.com";
      };
      core.autocrlf = "input";
      # WSL2 専用: Windows 側 1Password SSH Agent を使うため ssh.exe を呼ぶ。
      # 現状 Linux 構成は WSL2 のみだが、非 WSL の Linux を足す場合はここを見直すこと。
      core.sshCommand = pkgs.lib.mkIf pkgs.stdenv.isLinux "ssh.exe";
      init.defaultBranch = "main";
      gpg = {
        format = "ssh";
        # コミット署名は 1Password の SSH キーで行う。署名バイナリは OS で異なる。
        # WSL2: Windows 側 op-ssh-sign-wsl.exe(WindowsApps が WSL の PATH に乗るため
        #       ユーザー名を含む絶対パスにせず素の名前で解決させる)。
        # macOS: 1Password.app 同梱の op-ssh-sign。
        ssh.program =
          if pkgs.stdenv.isDarwin then
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
