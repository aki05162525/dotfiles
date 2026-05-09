{ ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig = {
      tools = {
        node = "24";
        go = "1.26";
      };
    };
  };
}
