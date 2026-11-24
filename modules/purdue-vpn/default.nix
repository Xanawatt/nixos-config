{ lib, pkgs, ... }:
let
  # name -> server; the name doubles as the tunnel interface (<=15 chars), which
  # the quickshell bar uses to tell which profiles are up
  profiles = {
    purdue = "webvpn.purdue.edu";
    purdue-itis = "webvpn.purdue.edu/vrf-itis";
    purdue-zone = "zonevpn.itap.purdue.edu/admn";
    pnw-nimm = "zonevpn.pnw.edu/nimm";
  };

  # openconnect runs as root under sudo, so it can't start the user's browser
  # on its own; this opens the SAML URL in the invoking user's Firefox.
  openBrowser = pkgs.writeShellScript "vpn-open-browser" ''
    U="''${SUDO_USER:-schne112}"
    exec ${pkgs.util-linux}/bin/runuser -u "$U" -- env \
      XDG_RUNTIME_DIR="/run/user/$(id -u "$U")" \
      WAYLAND_DISPLAY=wayland-1 DISPLAY=:0 \
      PATH=/run/current-system/sw/bin:/etc/profiles/per-user/$U/bin \
      firefox "$1" >/dev/null 2>&1 &
  '';

  vpn = pkgs.writeShellScriptBin "vpn" ''
    case "$1" in
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: server: ''
      ${name})
        shift
        exec sudo ${pkgs.openconnect}/bin/openconnect \
          --protocol=anyconnect \
          --interface=${name} \
          --external-browser=${openBrowser} \
          "$@" ${server}
        ;;'') profiles)}
    *)
      echo "usage: vpn <profile> [openconnect args]" >&2
      echo "profiles: ${lib.concatStringsSep " " (lib.attrNames profiles)}" >&2
      exit 1
      ;;
    esac
  '';
in
{
  environment.systemPackages = [ vpn ];
}
