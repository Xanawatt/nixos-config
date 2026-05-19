{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.asdm;

  asdmScript = pkgs.writeShellScriptBin "asdm" ''
    ASDMLIB="${cfg.asdmDir}"
    JAVA="${cfg.javaPackage}/bin/java"

    export GDK_BACKEND=x11
    export GDK_SCALE=2
    export GDK_DPI_SCALE=1
    export QT_SCALE_FACTOR=2
    export _JAVA_AWT_WM_NONREPARENTING=1

    exec "$JAVA" \
      -Xms64m \
      -Xmx512m \
      -Dswing.aatext=true \
      -Dawt.useSystemAAFontSettings=on \
      -Djdk.tls.client.protocols=TLSv1.2 \
      -cp "$ASDMLIB/asdm-launcher.jar:$ASDMLIB/jploader.jar:$ASDMLIB/lzma.jar:$ASDMLIB/retroweaver-rt-2.0.jar" \
      com.cisco.launcher.Launcher \
      "$ASDMLIB/cert.PEM"
  '';

  asdmDesktop = pkgs.makeDesktopItem {
    name = "asdm";
    desktopName = "Cisco ASDM";
    comment = "Cisco Adaptive Security Device Manager";
    exec = "asdm";
    terminal = false;
    categories = [ "Network" ];
    icon = cfg.icon;
  };

in
{
  options.services.asdm = {
    enable = mkEnableOption "Cisco ASDM launcher";

    asdmDir = mkOption {
      type = types.str;
      default = "$HOME/.local/opt/programs/asdm";
      description = "Directory containing ASDM jar files.";
    };

    javaPackage = mkOption {
      type = types.package;
      default = pkgs.jdk8;
      description = "Java package used to launch ASDM.";
    };

    forceX11 = mkOption {
      type = types.bool;
      default = true;
      description = "Force ASDM to use X11 instead of Wayland.";
    };

    icon = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional icon for the desktop entry.";
    };

    uiScale = mkOption {
      type = types.str;
      default = "2";
      description = "Java UI scaling factor for ASDM.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.javaPackage
      asdmScript
      asdmDesktop
    ];
  };
}
