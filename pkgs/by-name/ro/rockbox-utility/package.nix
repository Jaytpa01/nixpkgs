{
  lib,
  stdenv,
  fetchurl,
  cryptopp,
  libusb1,
  pkg-config,
  qt5,
  cmake,
  makeDesktopItem,
  copyDesktopItems,
  withEspeak ? false,
  espeak ? null,
}:

stdenv.mkDerivation rec {
  pname = "rockbox-utility";
  version = "1.5.1";

  src = fetchurl {
    url = "https://download.rockbox.org/rbutil/source/RockboxUtility-v${version}-src.tar.bz2";
    hash = "sha256-guNO11a0d30RexPEAAQGIgV9W17zgTjZ/LNz/oUn4HM=";
  };

  nativeBuildInputs = [
    pkg-config
    qt5.wrapQtAppsHook
    cmake
    copyDesktopItems
  ];

  # don't wrap qt apps automatically, we do that manually in the preFixup hook
  dontWrapQtApps = true;

  buildInputs = [
    cryptopp
    libusb1
    qt5.qttools
    qt5.qtmultimedia
  ] ++ lib.optional withEspeak espeak;

  # The RockboxUtility source archive that we fetch from is actually just a subset of the entire rockbox repo.
  # The utils/CMakesLists.txt references directories and libraries that aren't included in our archive.
  # Lets remove them so we can actually build the project without errors
  prePatch = ''
    cd utils
    sed -i '/add_subdirectory(themeeditor)/d' CMakeLists.txt
    sed -i '/add_library(skin_parser/,/target_compile_definitions(skin_parser/d' CMakeLists.txt
  '';

  installPhase = ''
    runHook preInstall

    cd rbutilqt
    install -Dm755 RockboxUtility $out/bin/rockboxutility
    ln -s $out/bin/rockboxutility $out/bin/RockboxUtility

    install -Dm644 ../../../docs/logo/rockbox-clef.svg \
    $out/share/icons/hicolor/scalable/apps/rockbox-clef.svg

    runHook postInstall
  '';

  preFixup = ''
    wrapQtApp $out/bin/rockboxutility \
    ${lib.optionalString withEspeak ''
      --prefix PATH : ${espeak}/bin
    ''}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "rockbox-utility";
      desktopName = "Rockbox Utility";
      comment = "Rockbox Installer and Maintenance Tool";
      exec = "RockboxUtility";
      type = "Application";
      icon = "rockbox-clef";
      categories = [ "Utility" ];
      startupNotify = true;
      terminal = false;
    })
  ];

  meta = with lib; {
    homepage = "https://www.rockbox.org";
    description = "Open source firmware for digital music players";
    longDescription = ''
      Rockbox is a free replacement firmware for digital music players.
      This is the automated installer tool for Rockbox.
    '';
    changelog = "https://www.rockbox.org/wiki/RockboxUtility#Change_Log";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ jaypta01 ];
    mainProgram = "RockboxUtility";
    platforms = platforms.linux;
  };
}
