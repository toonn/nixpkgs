{ stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation {
  pname = "darwin-stubs";
  version = "10.13.6";

  src = fetchurl {
    url = "https://github.com/toonn/darwin-stubs/archive/macOS-10.13.tar.gz";
    sha256 = "sha256-UcFa5QV3w/v5Bw+bDxm7045iQfWwQCBdZEIgv6qlmWs=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir $out
    mv stubs/10.13.6/* $out
  '';
}
