{ config, lib, ... }:

with lib;
let
  cfg = config.modules.git;
in

{
  #options.modules.git = {
  #  enable = true;
    # mkEnableOption "Git";
  #};

  #config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      settings = {
        init.defaultBranch = "main";

        user = {
          name = "Mark Schneider";
          email = "git@kitauji.net";
        };
      };
    };
  #};
}
