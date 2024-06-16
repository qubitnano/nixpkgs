{ callPackage
, fetchFromGitHub
, autoPatchelfHook
, zlib
, stdenvNoCC
}:

callPackage ./generic.nix {
  pname = "sm64ex-coop";
  version = "0-unstable-2023-11-26";

  src = fetchFromGitHub {
    owner = "djoslin0";
    repo = "sm64ex-coop";
    rev = "dd278f0b3f0174c864de10fff6e107ba6d296cef";
    sha256 = "sha256-Q+MdIL2M4VPmqrqyAlFSU+NctgwEO3tXrjinHFobY6o=";
  };

  extraNativeBuildInputs = [
    autoPatchelfHook
  ];

  extraBuildInputs = [
    zlib
  ];

  postInstall =
    let
      sharedLib = stdenvNoCC.hostPlatform.extensions.sharedLibrary;
    in
    ''
      mkdir -p $out/lib
      cp $src/lib/bass/libbass{,_fx}${sharedLib} $out/lib
      cp $src/lib/discordsdk/libdiscord_game_sdk${sharedLib} $out/lib
      cp -r $src/lang $out/share/sm64ex/lang
    '';

  extraMeta = {
    homepage = "https://github.com/djoslin0/sm64ex-coop";
    description = "Super Mario 64 online co-op mod, forked from sm64ex";
  };
}
