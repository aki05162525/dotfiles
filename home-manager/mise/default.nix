{ ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig = {
      tools = {
        node = "22";
        go = "1.26";
      };
    };
  };
}
