{ lib, rustPlatform, fetchFromGitHub, ... }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wally-package-types";
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "JohnnyMorganz";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-ynd5z2pbhGnPTKuJQG4EJL/Zy/X9lTCjSi8Cd6nRSsA=";
  };

  cargoHash = "sha256-LjtnArnv46GzbHnpT3wFNrjCv78stfFc6Kx9RefK+U8=";
})
