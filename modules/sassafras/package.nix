{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, openssl
, zlib
, fontconfig
, gtk2
, atk
, gdk-pixbuf
, glib
, pango
, libX11
}:

stdenv.mkDerivation rec {
  pname = "sassafras-keyaccess";
  version = "8.1.0.4-202603";

  src = fetchurl {
    url = "https://download.sassafras.com/software/release/current/Installers/Linux/Client/KeyAccess_${version}_amd64.deb";
    hash = "sha256-30qlM5IluSXGC84pGcNCWDzvUIPcx3qkrTFSpcGoRDk=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    openssl
    zlib
    fontconfig

    # X11
    libX11

    # GTK2 stack
    gtk2
    atk
    gdk-pixbuf
    glib
    pango
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out

    # Keep the normal Linux filesystem layout
    cp -r usr $out/
  '';

  meta = with lib; {
    description = "Sassafras KeyAccess inventory client";
    platforms = platforms.linux;
    license = licenses.unfree;
  };
}
