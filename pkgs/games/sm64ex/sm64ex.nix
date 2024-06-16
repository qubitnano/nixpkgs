{ callPackage
, fetchFromGitHub
}:

callPackage ./generic.nix {
  pname = "sm64ex";
  version = "0-unstable-2024-06-05";

  src = fetchFromGitHub {
    owner = "sm64pc";
    repo = "sm64ex";
    rev = "6f7d974a73037d8ae61fb5dff8e1aec40432e1f8";
    sha256 = "sha256-0poRccRQEYGfibv1W0OdoYE03zKr9+rwPMeD982wHZU=";
  };

  extraMeta = {
    homepage = "https://github.com/sm64pc/sm64ex";
    description = "Super Mario 64 port based off of decompilation";
  };
}

