{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/vscode/default.nix
#      ./modules/waybar/default.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Indiana/Indianapolis";

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.xanawatt = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
      fastfetch
    ];
  };

  security.sudo.extraRules = [{
    users = ["xanawatt"];
    commands = [{
      command = "ALL";
      options = ["NOPASSWD"];
    }];
  }];

  programs.hyprland = {
    enable = true;
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    alacritty
    pkgs.nix-ld
    hyprpaper
    foot
    kitty
    waybar
    rofi
    unzip

    # frc
    inputs.frc-nix.packages.${pkgs.stdenv.hostPlatform.system}.elastic-dashboard
    inputs.frc-nix.packages.${pkgs.stdenv.hostPlatform.system}.pathplanner
    inputs.frc-nix.packages.${pkgs.stdenv.hostPlatform.system}.roborioteamnumbersetter
    inputs.frc-nix.packages.${pkgs.stdenv.hostPlatform.system}.sysid
    inputs.frc-nix.packages.${pkgs.stdenv.hostPlatform.system}.wpilib-utility
    inputs.frc-nix.packages.${pkgs.stdenv.hostPlatform.system}.advantagescope
    inputs.frc-nix.packages.${pkgs.stdenv.hostPlatform.system}.vscode-wpilib

    grim
#    wayrecorder
    slurp
    wl-clipboard

    slack
    jq
    spotify
    plex-desktop
    securecrt
    file
    onedrive
    hyprlock
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
  ];

  nixpkgs.config.allowUnfree = true;    

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # this is to fix vscode
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  
  environment.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };
  programs.nix-ld.enable = true;

  networking.firewall.enable = false;

  system.stateVersion = "25.11"; # Did you read the comment?

}

