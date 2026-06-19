{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    ignores = [
      "**/.claude/settings.local.json"
      ".DS_Store"
    ];
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
        ssh.program = pkgs.lib.mkIf pkgs.stdenv.isDarwin "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
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
