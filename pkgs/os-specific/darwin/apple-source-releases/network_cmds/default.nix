{ lib, appleDerivation, xcbuildHook, stdenv
, openssl, Librpcsvc, xnu, libpcap, developer_cmds }:

appleDerivation {

  nativeBuildInputs = [ xcbuildHook ];
  buildInputs = [ openssl xnu Librpcsvc libpcap developer_cmds ];

  # Work around error from <stdio.h> on aarch64-darwin:
  #     error: 'TARGET_OS_IPHONE' is not defined, evaluates to 0 [-Werror,-Wundef-prefix=TARGET_OS_]
  NIX_CFLAGS_COMPILE = "-Wno-error=undef-prefix -I./unbound -I${xnu}/Library/Frameworks/System.framework/Headers/";

  patches = [
    ./0001-mtest-Define-INET6-as-a-value.patch
    ./0002-val_secalgo-Use-setter-because-DSA_SIG-is-now-opaque.patch
    ./0003-keyraw-Use-setter-for-opaque-structs.patch
    ./0004-val_secalgo-Replace-EVP_MD_CTX_cleanup-with-_free.patch
    ./0005-val_secalgo-EVP_dss1-was-dropped-in-1.0-in-favor-of-.patch
    ./0006-val_secalgo-Define-ctx-as-a-pointer.patch
    ./0007-val_secalgo-EVP_MD_CTX_free-shouldn-t-fail-as-oppose.patch
  ];

  # "spray" requires some files that aren't compiling correctly in xcbuild.
  # "rtadvd" seems to fail with some missing constants.
  # "traceroute6" and "ping6" require ipsec which doesn't build correctly
  prePatch = ''
    substituteInPlace network_cmds.xcodeproj/project.pbxproj \
      --replace "7294F0EA0EE8BAC80052EC88 /* PBXTargetDependency */," "" \
      --replace "7216D34D0EE89FEC00AE70E4 /* PBXTargetDependency */," "" \
      --replace "72CD1D9C0EE8C47C005F825D /* PBXTargetDependency */," "" \
      --replace "7216D2C20EE89ADF00AE70E4 /* PBXTargetDependency */," "" \
      --replace "libcrypto.35.dylib" "libcrypto.dylib" \
      --replace "libssl.35.dylib"    "libssl.dylib"
  '' + lib.optionalString stdenv.isAarch64 ''
    # "unbound" does not build on aarch64
    substituteInPlace network_cmds.xcodeproj/project.pbxproj \
      --replace "71D958C51A9455A000C9B286 /* PBXTargetDependency */," ""
  '';

  # temporary install phase until xcodebuild has "install" support
  installPhase = ''
    for f in Products/Release/*; do
      if [ -f $f ]; then
        install -D $f $out/bin/$(basename $f)
      fi
    done

    for n in 1 5; do
      mkdir -p $out/share/man/man$n
      install */*.$n $out/share/man/man$n
    done

    # TODO: patch files to load from $out/ instead of /usr/

    # mkdir -p $out/etc/
    # install rtadvd.tproj/rtadvd.conf ip6addrctl.tproj/ip6addrctl.conf $out/etc/

    # mkdir -p $out/local/OpenSourceVersions/
    # install network_cmds.plist $out/local/OpenSourceVersions/

    # mkdir -p $out/System/Library/LaunchDaemons
    # install kdumpd.tproj/com.apple.kdumpd.plist $out/System/Library/LaunchDaemons
 '';

  meta = {
    platforms = lib.platforms.darwin;
    maintainers = with lib.maintainers; [ matthewbauer ];
  };
}
