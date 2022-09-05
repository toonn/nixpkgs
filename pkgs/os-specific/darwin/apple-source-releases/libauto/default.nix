{ lib, stdenv, appleDerivation, libdispatch, Libsystem }:

appleDerivation {
  # these are included in the pure libc
  buildInputs = lib.optionals stdenv.cc.nativeLibc [ libdispatch Libsystem ];

  buildPhase = ''
    c++ -I. -O3 -c -Wno-c++11-extensions auto_zone.cpp
    c++ -Wl,-no_dtrace_dof --stdlib=libc++ -dynamiclib -install_name $out/lib/libauto.dylib -o libauto.dylib *.o
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    mv auto_zone.h $out/include
    mv libauto.dylib $out/lib
  '';

  meta = {
    # libauto is only used by objc4/pure.nix , but objc4 is now using the impure approach
    platforms = lib.platforms.darwin;
  };
}
