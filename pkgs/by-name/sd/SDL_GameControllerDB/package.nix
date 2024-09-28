{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  unstableGitUpdater,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "SDL_GameControllerDB";
  version = "0-unstable-2024-10-05";

  src = fetchFromGitHub {
    owner = "mdqinc";
    repo = "SDL_GameControllerDB";
    rev = "4672f1511d2a9e9bbbd21d4969fdc84b349d3ca0";
    hash = "sha256-9CGaO6Y5Nwgpg4yQkoP0o8D/aH86LJ11+5v11sG5Yvs=";
  };

  installPhase = ''
    install -Dm644 gamecontrollerdb.txt -t $out/share
    install -Dm644 LICENSE -t $out/share/licenses
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    description = "A community sourced database of game controller mappings to be used with SDL2 Game Controller functionality";
    homepage = "https://github.com/mdqinc/SDL_GameControllerDB";
    license = lib.licenses.zlib;
    maintainers = with lib.maintainers; [ qubitnano ];
    platforms = lib.platforms.all;
  };
})
