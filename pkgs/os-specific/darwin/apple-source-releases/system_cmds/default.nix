{ stdenv, appleDerivation, lib
, apple_sdk, CF, IOKit, Librpcsvc, libutil, openbsm, pam, xnu
}:

appleDerivation {
  # xcbuild fails with:
  # /nix/store/fc0rz62dh8vr648qi7hnqyik6zi5sqx8-xcbuild-wrapper/nix-support/setup-hook: line 1:  9083 Segmentation fault: 11  xcodebuild OTHER_CFLAGS="$NIX_CFLAGS_COMPILE" OTHER_CPLUSPLUSFLAGS="$NIX_CFLAGS_COMPILE" OTHER_LDFLAGS="$NIX_LDFLAGS" build
  # see issue facebook/xcbuild#188
  # buildInputs = [ xcbuild ];

  buildInputs = [ CF Librpcsvc libutil openbsm pam xnu IOKit
                ] ++ ( with apple_sdk.frameworks;
                       [ OpenDirectory ]
                ) ++ ( with apple_sdk.libs;
                       [ compression ]
                     );
  # NIX_CFLAGS_COMPILE = lib.optionalString hostPlatform.isi686 "-D__i386__"
  #                    + lib.optionalString hostPlatform.isx86_64 "-D__x86_64__"
  #                    + lib.optionalString hostPlatform.isAarch32 "-D__arm__";
  NIX_CFLAGS_COMPILE = [ "-DDAEMON_UID=1"
                         "-DDAEMON_GID=1"
                         "-DDEFAULT_AT_QUEUE='a'"
                         "-DDEFAULT_BATCH_QUEUE='b'"
                         "-DPERM_PATH=\"/usr/lib/cron/\""
                         "-DOPEN_DIRECTORY"
                         "-DNO_DIRECT_RPC"
                         "-DAPPLE_GETCONF_UNDERSCORE"
                         "-DAPPLE_GETCONF_SPEC"
                         "-DUSE_PAM"
                         "-DUSE_BSM_AUDIT"
                         "-D_PW_NAME_LEN=MAXLOGNAME"
                         "-D_PW_YPTOKEN=\"__YP!\""
                         "-DAHZV1=64 "
                         "-DAU_SESSION_FLAG_HAS_TTY=0x4000"
                         "-DAU_SESSION_FLAG_HAS_AUTHENTICATED=0x4000"
                       ] ++ lib.optional (!stdenv.isLinux) " -D__FreeBSD__ ";

  patchPhase = ''
    substituteInPlace kpgo.tproj/kpgo.c \
      --replace "sys/pgo.h" "bsd/sys/pgo.h"
    substituteInPlace login.tproj/login.c \
      --replace bsm/audit_session.h bsm/audit.h
    substituteInPlace login.tproj/login_audit.c \
      --replace bsm/audit_session.h bsm/audit.h
    substituteInPlace memory_pressure.tproj/memory_pressure.c \
      --replace sys/kern_memorystatus.h bsd/sys/kern_memorystatus.h
    substituteInPlace nvram.tproj/nvram.c \
      --replace IOKit/IOKitKeysPrivate.h iokit/IOKit/IOKitKeysPrivate.h
    substituteInPlace stackshot.tproj/stackshot.c \
      --replace kern/debug.h osfmk/kern/debug.h \
      --replace sys/stackshot.h bsd/sys/stackshot.h
    substituteInPlace taskpolicy.tproj/taskpolicy.c \
      --replace sys/spawn_internal.h bsd/sys/spawn_internal.h
    sed -i 's/#include <stdlib.h>/#define PRIVATE 1\n#include <bsd\/sys\/resource.h>\n#undef PRIVATE\n\0/' \
      taskpolicy.tproj/taskpolicy.c
  '' + lib.optionalString stdenv.isAarch64 ''
    substituteInPlace sysctl.tproj/sysctl.c \
      --replace "GPROF_STATE" "0"
    substituteInPlace login.tproj/login.c \
      --replace "defined(__arm__)" "defined(__arm__) || defined(__arm64__)"
    
  '';

  buildPhase = ''
    for dir in *.tproj; do
      name=$(basename $dir)
      name=''${name%.tproj}

      CFLAGS=""
      case $name in
           atrun) CFLAGS="-Iat.tproj";;
           chkpasswd)
             CFLAGS="-framework OpenDirectory -framework CoreFoundation -lpam";;
           dmesg) CFLAGS="-I${xnu}/include/bsd -I${xnu}/include/osfmk";;
           getconf)
               for f in getconf.tproj/*.gperf; do
                   cfile=''${f%.gperf}.c
                   LC_ALL=C awk -f getconf.tproj/fake-gperf.awk $f > $cfile
               done
           ;;
           iostat) CFLAGS="-framework IOKit -framework CoreFoundation";;
           login) CFLAGS="-lbsm -lpam";;
           ltop) CFLAGS="-I${xnu}/include/bsd -I${xnu}/include/osfmk -I${xnu}/include/san";;
           nvram) CFLAGS="-framework CoreFoundation -framework IOKit";;
           proc_uuid_policy) CFLAGS="-I${xnu}/include/bsd -I${xnu}/include/osfmk -I${xnu}/include/san";;
           sadc) CFLAGS="-framework IOKit -framework CoreFoundation";;
           sar) CFLAGS="-Isadc.tproj";;
           taskpolicy) CFLAGS="-I${xnu.privateHeaders} -I${xnu}/include/osfmk -I${xnu}/include/san";;
           vm_purgeable_stat) CFLAGS="-I${xnu}/include/bsd -I${xnu}/include/osfmk -I${xnu}/include/san";;
      esac

      case $name in
           # These are all broken currently.
           arch | \
           chpass | \
           fs_usage | \
           gcore | \
           latency | \
           lskq | \
           lsmp | \
           passwd | \
           reboot | \
           sc_usage | \
           shutdown | \
           trace | \
           zprint)
             echo "Skipping $name"
             continue;;
      esac

      echo "Building $name"

      case $name in
        pagesize) install $dir/pagesize.sh pagesize;;
        *) cc $dir/*.c -I''${dir} $CFLAGS -o $name;;
      esac
    done
  '';

  installPhase = ''
    for dir in *.tproj; do
      name=$(basename $dir)
      name=''${name%.tproj}
      [ -x $name ] && install -D $name $out/bin/$name
      for n in 1 2 3 4 5 6 7 8 9; do
        for f in $dir/*.$n; do
          install -D $f $out/share/man/man$n/$(basename $f)
        done
      done
    done
  '';

  meta = {
    platforms = lib.platforms.darwin;
    maintainers = with lib.maintainers; [ shlevy matthewbauer ];
  };
}
