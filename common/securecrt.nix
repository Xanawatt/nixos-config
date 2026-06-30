{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,

  cups,
  gtkmm3,
  icu74,
  krb5,
  makeWrapper,
  openssl,
  pango,
  python312,
  xcb-util-cursor,
  xorg,
}:

let
  packageId = "scrt_ubuntu2464_deb_972";
in stdenv.mkDerivation rec {
  pname = "securecrt";
  version = "9.7.2";

  src = fetchurl {
    url = "https://www.vandyke.com/cgi-bin/download_1.php";
    name = "${pname}-${version}.deb";
    curlOptsList = [
      "-X" "POST" "--data" "pid=scrt_ubuntu2464_deb_972&export_check=accept&country=no&su"
      #"-H" "User-Agent: Mozilla/5.0"
    ];
    sha256 = "sha256-5DMdYUPRp63+BmFcDXzoEvZIS7U20m9BA1FjD4NULA4=";
    #sha256-4lW891pmVMFdJVKiZjXE169rioCLrOgGoZutquOncSo=";
  };

  unpackCmd = "dpkg -x $curSrc source";

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    cups
    gtkmm3
    icu74
    krb5
    makeWrapper
    openssl
    pango
    python312
    xcb-util-cursor
    xorg.xcbutilkeysyms
    xorg.xcbutilwm
  ];

  dontConfigure = true;
  dontBuild = true;
  dontWrapQTApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -R usr/* "$out/"
    #wrapProgram "$out/bin/SecureCRT" --set QT_QPA_PLATFORM_PLUGIN_PATH "$out/lib/scrt/plugins/platforms"

    wrapProgram "$out/bin/SecureCRT" \
      --set QT_QPA_PLATFORM_PLUGIN_PATH "$out/lib/scrt/plugins/platforms" #\
#      --set QT_QPA_PLATFORM xcb #\
#      --set QT_SCALE_FACTOR 1.5    
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://www.vandyke.com/products/securecrt/unix.html";
    description = "Terminal emulator for computing professionals, with advanced session management";
    license = {
      free = false;
      fullName = "Unknown / Custom";
    };

    platforms = with lib.platforms; linux ++ darwin ++ windows;
    broken = !(stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64);
  };

  mainProgram = "SecureCRT";
}
