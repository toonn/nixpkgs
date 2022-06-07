{ lib, appleDerivation', stdenv, xcbuildHook, ncurses }:

appleDerivation' stdenv {

  patchPhase = ''
    for f in local/{tokenizer,history}n.c; do
      substituteInPlace "$f" --replace "./" "../src/"
    done

    substituteInPlace xcodescripts/install_misc.sh \
      --replace '-g $ALTERNATE_GROUP' "" \
      --replace '-o $ALTERNATE_OWNER' "" \
      --replace '-m $ALTERNATE_MODE'  ""
  '';
  
  nativeBuildInputs = [ xcbuildHook ];

  buildInputs = [ ncurses ];

  # temporary install phase until xcodebuild has "install" support
  installPhase = ''
    mkdir -p $out/usr/lib
    # The install script creates symlinks to this name and on my system
    # /usr/include/libedit.3.dylib is indeed the only non-symlink
    mv Products/Release/libedit.dylib $out/usr/lib/libedit.3.dylib

    export DSTROOT=$out
    export SRCROOT=$PWD

    xcodescripts/install_misc.sh

    mv $out/usr/* $out
    rmdir $out/usr
  '';

  meta = with lib; {
    maintainers = with maintainers; [ toonn ];
    platforms   = platforms.darwin;
    license     = with licenses; [ bsd2 bsd3 ];
  };
}
