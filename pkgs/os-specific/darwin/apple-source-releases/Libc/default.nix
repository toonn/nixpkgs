{ appleDerivation', stdenvNoCC, ed, Libc-10_9_2, unifdef }:

appleDerivation' stdenvNoCC {
  nativeBuildInputs = [ ed unifdef ];

  patches = [
    ./0001-Define-TARGET_OS_EMBEDDED-in-std-lib-io-if-not-defin.patch
  ];

  installPhase = ''
    export SRCROOT=$PWD
    export DSTROOT=$out
    export PUBLIC_HEADERS_FOLDER_PATH=include
    export PRIVATE_HEADERS_FOLDER_PATH=include
    bash xcodescripts/headers.sh

    cp ${./CrashReporterClient.h} $out/include/CrashReporterClient.h

    # The most recent version that still had `NSSystemDirectories.h`
    # The header is deprecated but ICU still depends on it.
    cp ${Libc-10_9_2}/include/NSSystemDirectories.h $out/include

    for h in pthread{,_impl,_spis}.h sched.h; do
      ln -s pthread/"$h" $out/include/"$h"
    done
  '';

  appleHeaders = builtins.readFile ./headers.txt;
}
