# vertoxr.nix — run the prebuilt VertoXR Linux beta on NixOS.
#
# Usage: add to your imports in configuration.nix (or a flake module):
#   imports = [ ./vertoxr.nix ];
# then on the host that should have it:
#   vertoxr.enable = true;
#   vertoxr.user = "yourname";
# Importing without enabling does nothing, so it's safe in a shared module list.
#
# VertoXR ships a binary built for Ubuntu, so this wraps it in an FHS
# environment that provides the libraries its Linux guide lists for apt
# (mapped to their nixpkgs names), plus the usual Flutter/Chromium runtime libs.
{ config, lib, pkgs, ... }:

let
  cfg = config.vertoxr;

  # Where you unpacked the download. Override per-run with VERTOXR_BIN.
  defaultBin = "$HOME/.local/opt/vertoxr/verto_xr";

  vertoxr-fhs = pkgs.buildFHSEnv {
    name = "vertoxr";

    targetPkgs = p: with p; [
      # --- from the VertoXR apt list ---
      keybinder3            # keybinder-3.0
      alsa-lib              # libasound2
      udev                  # libudev
      openssl               # libssl
      gtk3                  # libgtk-3
      pipewire              # libpipewire-0.3 (GNOME Wayland virtual displays)
      libinput
      nss nspr
      at-spi2-core at-spi2-atk   # libatk1.0 / libatk-bridge2.0
      cups                  # libcups2
      libdrm
      (p.libgbm or p.mesa)  # libgbm1 (split out of mesa in newer nixpkgs)
      pango cairo
      libayatana-appindicator

      # --- common runtime deps for Flutter/Chromium-style bundles ---
      glib dbus expat zlib fontconfig freetype
      libepoxy libGL vulkan-loader mesa
      libxkbcommon wayland
      xorg.libX11 xorg.libXext xorg.libXrandr xorg.libXcomposite
      xorg.libXdamage xorg.libXfixes xorg.libXi xorg.libXrender
      xorg.libXtst xorg.libxcb xorg.libxshmfence
      libsecret
      stdenv.cc.cc.lib

      # GTK's own deps — buildFHSEnv doesn't pull these in transitively
      gdk-pixbuf harfbuzz fribidi libthai graphene
      xorg.libXcursor xorg.libXinerama
      libuuid libgcrypt libgpg-error
    ];

    # The sandbox builds its own /etc, and the `udev` package above brings an
    # /etc/udev that hides the host's. Bind the real one in so the app (and
    # libudev) see the system's rules — including 70-vertoxr-drivers.rules.
    extraBwrapArgs = [ "--ro-bind-try" "/etc/udev" "/etc/udev" ];

    # `vertoxr`            -> launches $VERTOXR_BIN or the default path
    # `vertoxr some/cmd`   -> runs that command inside the FHS env (handy for
    #                         debugging with ldd, or running an AppImage)
    runScript = pkgs.writeShellScript "vertoxr-launch" ''
      export APPIMAGE_EXTRACT_AND_RUN=1   # in case the download is an AppImage (no FUSE needed)
      if [ $# -gt 0 ]; then exec "$@"; fi
      exec "''${VERTOXR_BIN:-${defaultBin}}"
    '';
  };
  # App-launcher entry (buildFHSEnv doesn't create one on its own).
  vertoxr-desktop = pkgs.makeDesktopItem {
    name = "vertoxr";
    desktopName = "VertoXR";
    comment = "Spatial workstation for XR glasses";
    exec = "${vertoxr-fhs}/bin/vertoxr";
    icon = "video-display";   # swap for a path to VertoXR's own icon if the download ships one
    categories = [ "Utility" ];
    terminal = false;
  };
in
{
  options.vertoxr = {
    enable = lib.mkEnableOption "VertoXR (FHS-wrapped Linux beta)";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User who runs VertoXR (added to input/plugdev).";
    };

    # Fill in your glasses' USB vendor ID(s) from `lsusb` (the part before the colon
    # in "ID xxxx:yyyy"). Leaves hidraw access to the logged-in seat user.
    glassesVendorIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "abcd" ];
      description = "USB vendor IDs of your XR glasses, lowercase hex, no 0x.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ vertoxr-fhs vertoxr-desktop ];

    # Global shortcuts use evdev; VertoXR recommends the input (and/or plugdev) group.
    # NixOS has `input` but no `plugdev` by default, so create it.
    users.groups.plugdev = { };
    users.users.${cfg.user}.extraGroups = [ "input" "plugdev" ];

    # Head-tracking IMU access on the glasses (hidraw).
    services.udev.extraRules = lib.concatMapStrings (vid: ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="${vid}", MODE="0660", GROUP="plugdev", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="${vid}", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    '') cfg.glassesVendorIds;

    # VertoXR's own udev rules. NixOS manages /etc/udev/rules.d itself, so the
    # app's "sudo cp ..." step can't work. Instead, drop its rules file next to
    # this module as 70-vertoxr-drivers.rules (and `git add` it); it's picked up here.
    services.udev.packages = lib.optional (builtins.pathExists ./70-vertoxr-drivers.rules)
      (pkgs.writeTextFile {
        name = "vertoxr-udev-rules";
        text = builtins.readFile ./70-vertoxr-drivers.rules;
        destination = "/lib/udev/rules.d/70-vertoxr-drivers.rules";
      });

    # PipeWire + portals for the GNOME Wayland virtual-display path.
    services.pipewire.enable = lib.mkDefault true;
    xdg.portal.enable = lib.mkDefault true;
  };
}
