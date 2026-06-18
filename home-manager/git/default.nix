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
