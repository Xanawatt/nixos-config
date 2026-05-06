{ config, pkgs, inputs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
#    waybar = "waybar";
    hypr = "hypr";
  };
in


{
  imports = [
    ./modules/git/default.nix
    ./modules/waybar/default.nix
#    ./modules/vscode/default.nix
  ];

  home.username = "xanawatt";
  home.homeDirectory = "/home/xanawatt";
  programs.git.enable = true;
  home.stateVersion = "25.11";
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos, btw";
    };
  };
  home.packages = with pkgs; [
#    vscode
  ];
  #home.file.".config/waybar".source = ./config/waybar;
  #home.file.".config/hypr".source = ./config/hypr;

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;

}
