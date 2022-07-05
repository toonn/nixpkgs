{ lib, appleDerivation }:

appleDerivation {
  dontBuild = true;

  # install headers only
  installPhase = ''
    mkdir $out
    cp -R include $out/include
  '';

  appleHeaders = ''
    malloc/malloc.h
  '';

  meta = with lib; {
    maintainers = with maintainers; [ toonn ];
    platforms   = platforms.darwin;
    license     = licenses.apsl20;
  };
}
