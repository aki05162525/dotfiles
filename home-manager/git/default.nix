{ ... }:

{
  programs.git = {
    enable = true;
    ignores = [
      "**/.claude/settings.local.json"
      ".DS_Store"
    ];
    settings = {
      user = {
        name = "aki05162525";
        email = "akihiro05162525@gmail.com";
      };
      core.autocrlf = "input";
      core.sshCommand = "ssh.exe";
      init.defaultBranch = "main";
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
