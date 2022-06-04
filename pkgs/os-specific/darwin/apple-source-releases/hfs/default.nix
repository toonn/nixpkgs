{ appleDerivation', stdenv, stdenvNoCC, lib, headersOnly ? true }:

appleDerivation' (if headersOnly then stdenvNoCC else stdenv) {
  installPhase = lib.optionalString headersOnly ''
    mkdir -p $out/include/hfs
    cp core/hfs_{format,mount,unistr}.h $out/include/hfs
  '';

  # /usr/include/hfs has hfs_format.h, hfs_mount.h and hfs_unistr.h
  appleHeaders = ''
    hfs/hfs_format.h
    hfs/hfs_mount.h
    hfs/hfs_unistr.h
  '';

  meta = {
    # Seems nobody wants its binary, so we didn't implement building.
    broken = !headersOnly;
    platforms = lib.platforms.darwin;
  };
}
