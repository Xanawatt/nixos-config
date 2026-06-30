{ config, lib, pkgs, ... }:

let
  cfg = config.services.sassafras;

  sassafrasPkg = pkgs.callPackage ./package.nix {};
in
{
  options.services.sassafras = {
    enable = lib.mkEnableOption "Sassafras KeyAccess client";
  };

  config = lib.mkIf cfg.enable {

    # Install binaries system-wide (optional but useful for debugging)
    environment.systemPackages = [
      sassafrasPkg
    ];

    # Ensure runtime state directory exists
    systemd.tmpfiles.rules = [
      "d /var/lib/KeyAccess 0755 root root -"
    ];

    # Main daemon
    systemd.services.keyaccess = {
      description = "Sassafras KeyServer Platform client daemon";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "forking";

        ExecStart = "${sassafrasPkg}/usr/libexec/karl -d -i /run/keyaccess.pid";

        PIDFile = "/run/keyaccess.pid";

        KillMode = "process";
        TimeoutStopSec = "20s";

        NoNewPrivileges = true;
      };
    };
  };
}
