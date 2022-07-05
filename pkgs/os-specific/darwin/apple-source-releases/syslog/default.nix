{ lib, appleDerivation }:

appleDerivation {
  dontBuild = true;

  # We only need the `asl.h` header
  installPhase = ''
    mkdir -p $out/include
    cp libsystem_asl.tproj/include/asl.h $out/include
  '';

  appleHeaders = ''
    asl.h
  '';

  meta = with lib; {
    maintainers = with maintainers; [ toonn ];
    platforms   = platforms.darwin;
    license     = licenses.apsl20;
  };
}
