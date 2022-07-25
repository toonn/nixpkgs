{ lib, appleDerivation, xcbuildHook, xpc }:

appleDerivation {
  buildInputs = [ xpc ];

  nativeBuildInputs = [ xcbuildHook ];

  outputs = [ "out" "dev" ];

  xcbuildFlags = [ "-target" "util" ];

  installPhase = ''
    mkdir -p $out/lib $out/include

    cp Products/Release/*.dylib $out/lib

    # TODO: figure out how to get this to be right the first time around
    install_name_tool -id $out/lib/libutil.dylib $out/lib/libutil.dylib

    cp mntopts.h $out/include
  '';

  # FIXME: Header checking doesn't work with multiple outputs 
  # appleHeaders = ''
  #   mntopts.h
  # '';

  meta = with lib; {
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.apsl20;
  };
}
