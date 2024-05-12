{
  stdenv,
  cmake,
  lsb-release,
  ninja,
  lib,
  fetchFromGitHub,
  fetchurl,
  copyDesktopItems,
  makeDesktopItem,
  python3,
  libX11,
  libXrandr,
  libXinerama,
  libXcursor,
  libXi,
  libXext,
  glew,
  boost,
  SDL2,
  SDL2_net,
  pkg-config,
  libpulseaudio,
  libpng,
  imagemagick,
  gnome,
  makeWrapper,
  imgui,
  stormlib,
  libzip,
  nlohmann_json,
  tinyxml-2,
  spdlog,
  stb,
  writeTextFile,
  fetchpatch
}:

let

  imgui' = imgui.overrideAttrs rec {
    version = "1.90.0";
    src = fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      rev = "ce0d0ac8298ce164b5d862577e8b087d92f6e90e";
      hash = "sha256-sBlc57brB/+Tv3djgB4HeEdeXtLz97shhgfCm8RkpF0=";
    };
  };

  # This would get fetched at build time otherwise, see:
  # https://github.com/HarbourMasters/Shipwright/blob/e46c60a7a1396374e23f7a1f7122ddf9efcadff7/soh/CMakeLists.txt#L736
  gamecontrollerdb = fetchurl {
    name = "gamecontrollerdb.txt";
    url = "https://raw.githubusercontent.com/gabomdq/SDL_GameControllerDB/80abcd32afa2515fc949139cdef5276c9dd055e2/gamecontrollerdb.txt";
    hash = "sha256-oUMs/Ah+NXMb02um5cegZUMjvsUgyKK9xEhk88WTJEA=";
  };

  thread_pool = fetchFromGitHub {
    owner = "bshoshany";
    repo = "thread-pool";
    rev = "v4.1.0";
    hash = "sha256-zhRFEmPYNFLqQCfvdAaG5VBNle9Qm8FepIIIrT9sh88=";
  };

  stb_impl = writeTextFile {
    name = "stb_impl.c";
    text = ''
      #define STB_IMAGE_IMPLEMENTATION
      #include "stb_image.h"
    '';
  };

  stb' = fetchurl {
    name = "stb_image.h";
    url = "https://raw.githubusercontent.com/nothings/stb/0bc88af4de5fb022db643c2d8e549a0927749354/stb_image.h";
    hash = "sha256-xUsVponmofMsdeLsI6+kQuPg436JS3PBl00IZ5sg3Vw=";
  };

  stormlib' = stormlib.overrideAttrs (prev: rec {
    version = "9.25";
    src = fetchFromGitHub {
      owner = "ladislav-zezula";
      repo = "StormLib";
      rev = "v${version}";
      hash = "sha256-HTi2FKzKCbRaP13XERUmHkJgw8IfKaRJvsK3+YxFFdc=";
    };
    buildInputs = prev.buildInputs ++ [
      pkg-config
    ];
    patches = (prev.patches or [ ]) ++ [
     (fetchpatch {
        name = "stormlib-optimzations.patch";
        url = "https://github.com/ladislav-zezula/StormLib/commit/ff338b230544f8b2bb68d2fbe075175ed2fd758c.patch";
        hash = "sha256-Jbnsu5E6PkBifcx/yULMVC//ab7tszYgktS09Azs5+4=";
      })
    ];

  });

  libgfxd = fetchFromGitHub {
    owner = "glankk";
    repo = "libgfxd";
    rev = "008f73dca8ebc9151b205959b17773a19c5bd0da";
    hash = "sha256-AmHAa3/cQdh7KAMFOtz5TQpcM6FqO9SppmDpKPTjTt8=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "shipwright";
  version = "8.0.5-unstable-2024-06-02";

  src = fetchFromGitHub {
    owner = "harbourmasters";
    repo = "shipwright";
    rev = "736dccb00b161a007a387b04267bdc30ef91e0af";
    hash = "sha256-bTEegMvD2vvhc7H82i+mmLM6DRHY4K25bvYkS6oU4KU=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    lsb-release
    python3
    imagemagick
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = [
    boost
    # libX11
    # libXrandr
    # libXinerama
    # libXcursor
    # libXi
    # libXext
    # glew
    SDL2
    SDL2_net
    libpulseaudio
    libpng
    gnome.zenity
    imgui'
    stormlib
    libzip
    nlohmann_json
    tinyxml-2
    spdlog
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}/lib"
    "-DFETCHCONTENT_SOURCE_DIR_IMGUI=${imgui'.src}"
    "-DFETCHCONTENT_SOURCE_DIR_STORMLIB=${stormlib}"
    "-DFETCHCONTENT_SOURCE_DIR_LIBGFXD=${libgfxd}"
    "-DFETCHCONTENT_SOURCE_DIR_THREADPOOL=${thread_pool}"
    (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
    (lib.cmakeBool "NON_PORTABLE" true)
  ];

  dontAddPrefix = true;

  # Linking fails without this
  hardeningDisable = [ "format" ];

  preConfigure = ''
    mkdir stb
    cp ${stb}/include/stb/stb_image.h ./stb
    cp ${stb_impl} ./stb/${stb_impl.name}

    substituteInPlace libultraship/cmake/dependencies/common.cmake \
      --replace-fail "\''${STB_DIR}" "/build/source/stb"
  '';

  patches = [
    # Remove vendored dependencies
    ./0001-deps.patch
  ];

  postBuild = ''
    cp ${gamecontrollerdb} ${gamecontrollerdb.name}
    pushd ../OTRExporter
    python3 ./extract_assets.py -z ../build/ZAPD/ZAPD.out --norom --xml-root ../soh/assets/xml --custom-assets-path ../soh/assets/custom --custom-otr-file soh.otr --port-ver ${finalAttrs.version}
    popd
  '';

  preInstall = ''
    # Cmake likes it here for its install paths
    cp ../OTRExporter/soh.otr ..
  '';

  postInstall = ''
    mkdir -p $out/bin
    ln -s $out/lib/soh.elf $out/bin/soh
    install -Dm644 ../soh/macosx/sohIcon.png $out/share/pixmaps/soh.png
  '';

  fixupPhase = ''
    wrapProgram $out/lib/soh.elf --prefix PATH ":" ${lib.makeBinPath [ gnome.zenity ]}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "soh";
      icon = "soh";
      exec = "soh";
      comment = finalAttrs.meta.description;
      genericName = "Ship of Harkinian";
      desktopName = "soh";
      categories = [ "Game" ];
    })
  ];

  meta = {
    homepage = "https://github.com/HarbourMasters/Shipwright";
    description = "A PC port of Ocarina of Time with modern controls, widescreen, high-resolution, and more";
    mainProgram = "soh";
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [
      ivar
      j0lol
    ];
    license = with lib.licenses; [
      # OTRExporter, OTRGui, ZAPDTR, libultraship
      mit
      # Ship of Harkinian itself
      unfree
    ];
  };
})
