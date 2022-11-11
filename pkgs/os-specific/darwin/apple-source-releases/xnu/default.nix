{ appleDerivation', lib, stdenv, stdenvNoCC, buildPackages
, bootstrap_cmds, bison, flex
, gnum4, unifdef, perl, python3
, headersOnly ? true
}:

appleDerivation' (if headersOnly then stdenvNoCC else stdenv) (
  let arch = if stdenv.isx86_64 then "x86_64" else "arm64";
  in
  {
  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [ bootstrap_cmds bison flex gnum4 unifdef perl python3 ];

  outputs = [ "out" "privateHeaders" ];

  patches = lib.optional stdenv.isx86_64 [
    ./python3.patch
    ./0001-Implement-missing-availability-platform.patch
  ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace "/bin/" "" \
      --replace "MAKEJOBS := " '# MAKEJOBS := '

    substituteInPlace makedefs/MakeInc.cmd \
      --replace "/usr/bin/" "" \
      --replace "/bin/" ""

    substituteInPlace makedefs/MakeInc.def \
      --replace "-c -S -m" "-c -m"

    substituteInPlace makedefs/MakeInc.top \
      --replace "MEMORY_SIZE := " 'MEMORY_SIZE := 1073741824 # '

    substituteInPlace libkern/kxld/Makefile \
      --replace "-Werror " ""

    substituteInPlace SETUP/kextsymboltool/Makefile \
      --replace "-lstdc++" "-lc++"

    substituteInPlace libsyscall/xcodescripts/mach_install_mig.sh \
      --replace "/usr/include" "/include" \
      --replace 'MIG=`' "# " \
      --replace 'MIGCC=`' "# " \
      --replace '$SRC/$mig' '-I$DSTROOT/include $SRC/$mig' \
      --replace '$SRC/servers/netname.defs' '-I$DSTROOT/include $SRC/servers/netname.defs' \
      --replace '$BUILT_PRODUCTS_DIR/mig_hdr' '$BUILT_PRODUCTS_DIR'

    # Going forward we need to patch the Availability headers for all the
    # missing versions that are no longer included but can be used throughout
    # the source releases. On a macOS system or in the SDK the Availability
    # headers do include all the necessary versions.
    underscored() {
      printf '%s' "''${1//./_}"
    }

    compareVersions() {
      # Versions are expected to not have more than three components separated
      # by dots, i.e. X[.Y[.Z]], each of which comprises no more than three
      # digits and elided components are considered equal to zero.
      lhs="0$1.0.0"
      rhs="0$2.0.0"
      l_major=$(printf '%03s' "''${lhs%%.*}")
      l_minor_patch=''${lhs#*.}
      l_minor=$(printf '%03s' "''${l_minor_patch%%.*}")
      l_rest=''${l_minor_patch#*.}
      l_patch=$(printf '%03s' "''${l_rest%%.*}")
      r_major=$(printf '%03s' "''${rhs%%.*}")
      r_minor_patch=''${rhs#*.}
      r_minor=$(printf '%03s' "''${r_minor_patch%%.*}")
      r_rest=''${r_minor_patch#*.}
      r_patch=$(printf '%03s' "''${r_rest%%.*}")
      if [ "$l_major" '<' "$r_major" ]; then
        printf 'LT'
      elif [ "$l_major" '>' "$r_major" ]; then
        printf 'GT'
      elif [ "$l_minor" '<' "$r_minor" ]; then
        printf 'LT'
      elif [ "$l_minor" '>' "$r_minor" ]; then
        printf 'GT'
      elif [ "$l_patch" '<' "$r_patch" ]; then
        printf 'LT'
      elif [ "$l_patch" '>' "$r_patch" ]; then
        printf 'GT'
      else
        printf 'EQ'
      fi
    }

    ALL_VERSIONS='10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9 10.10 10.10.2 10.10.3 10.11 10.11.2 10.11.3 10.11.4 10.12 10.12.1 10.12.2 10.12.4 10.13 10.13.1 10.13.2 10.13.4 10.14 10.14.1'
    versions() {
      start=$1
      end=$2
      format_string='%s'
      for v in $ALL_VERSIONS; do
        if [ $(compareVersions "$start" "$v") = GT ]; then
          continue
        elif [ $(compareVersions "$v" "$end") = GT ]; then
          break
        else
          printf "$format_string" "$v"
          format_string=' %s'
        fi
      done
    }

    version_defines() {
      version_prefix=$1
      infix_space=$2
      for missing_version in $(versions 10.13 10.14.1); do
        major=''${missing_version%%.*}
        minor_patch=''${missing_version#*.}
        minor=''${minor_patch%%.*}
        minor_patch_default="$minor_patch.0"
        patch_default=''${minor_patch_default#*.}
        patch=''${patch_default%%.*}
        decimal=$(printf '%02s%02s%02s' "$major" "$minor" "$patch")
        printf "#define %s_%-7s%s%s\n" \
          "$version_prefix" "$(underscored "$missing_version")" \
          "$infix_space" "$decimal"
      done
    }

    MAC_NA_COMMENT='/* __MAC_NA is not defined to a value but is uses as a token by macros to indicate that the API is unavailable */'
    VERSION_DEFINES_A_H=$(
      version_defines '__MAC' '       '
      printf '%s\n' "$MAC_NA_COMMENT"
    )
    substituteInPlace EXTERNAL_HEADERS/Availability.h \
      --replace "$MAC_NA_COMMENT" "$VERSION_DEFINES_A_H"

    MAC_10_12_4='#define MAC_OS_X_VERSION_10_12_4    101204';
    VERSION_DEFINES_AM_H=$(
      printf '%s\n' "$MAC_10_12_4"
      version_defines 'MAC_OS_X_VERSION' '    '
    )

    substituteInPlace EXTERNAL_HEADERS/AvailabilityMacros.h \
      --replace "$MAC_10_12_4" "$VERSION_DEFINES_AM_H" \
      --replace \
        ' * if max OS not specified, assume larger of (10.12.4, min)' \
        ' * if max OS not specified, assume larger of (10.14.1, min)' \
      --replace \
        '    #if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_12_4' \
        '    #if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_14_1' \
      --replace \
        '        #define MAC_OS_X_VERSION_MAX_ALLOWED MAC_OS_X_VERSION_10_12_4' \
        '        #define MAC_OS_X_VERSION_MAX_ALLOWED MAC_OS_X_VERSION_10_14_1'

    # As of macOS 10.13 the __MAC_NA macro was introduced to symbolize a lack
    # of introduction version for example, instead of providing an old version
    # as a harmless default.
    sed -i -e \
      '/__OSX_AVAILABLE_/s/4_0/NA/g' \
      EXTERNAL_HEADERS/AvailabilityMacros.h

    availability_block() {
      version=$1
      deprecation_version=$2
      if [ -z "$deprecation_version" ]; then
        availability_var="AVAILABLE_MAC_OS_X_VERSION_$(underscored "$version")_AND_LATER"
        availability_macro="__OSX_AVAILABLE_STARTING(__MAC_$(underscored "$version"), __IPHONE_NA)"
      else
        if [ -z "$3" ] && [ "$version" = "$deprecation_version" ]; then
          availability_var="DEPRECATED_IN_MAC_OS_X_VERSION_$(underscored "$version")_AND_LATER"
          availability_macro="__OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_$(underscored "$deprecation_version"), __IPHONE_NA, __IPHONE_NA)"
        else
          if [ -n "$3" ]; then
            availability_var="AVAILABLE_MAC_OS_X_VERSION_$(underscored "$version")_AND_LATER_BUT_DEPRECATED"
          else
            availability_var="AVAILABLE_MAC_OS_X_VERSION_$(underscored "$version")_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_$(underscored "$deprecation_version")"
          fi
          availability_macro="__OSX_AVAILABLE_BUT_DEPRECATED(__MAC_$(underscored "$version"), __MAC_$(underscored "$deprecation_version"), __IPHONE_NA, __IPHONE_NA)"
        fi
        availability_var_def="AVAILABLE_MAC_OS_X_VERSION_$(underscored "$version")_AND_LATER"
      fi
      printf '/*\n'
      printf ' * %s\n' "$availability_var"
      printf ' *\n'
      if [ -z "$3" ] && [ "$version" = "$deprecation_version" ]; then
        printf ' * Used on types deprecated in Mac OS X %s\n' "$version"
      else
        printf ' * Used on declarations introduced in Mac OS X %s' "$version"
        if [ -z "$deprecation_version" ]; then
          printf ' \n'
        elif [ "$version" = "$deprecation_version" ]; then
          printf ',\n * and deprecated in Mac OS X %s\n' "$deprecation_version"
        else
          printf ',\n * but later deprecated in Mac OS X %s\n' \
            "$deprecation_version"
        fi
      fi
      printf ' */\n'
      printf '#if __AVAILABILITY_MACROS_USES_AVAILABILITY\n'
      printf '    #define %s    %s\n' "$availability_var" "$availability_macro"
      if [ -z "$deprecation_version" ]; then
        printf '#elif MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_%s\n' \
          "$(underscored "$version")"
        printf '    #define %s     UNAVAILABLE_ATTRIBUTE\n' "$availability_var"
        printf '#elif MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_%s\n' \
          "$(underscored "$version")"
        printf '    #define %s     WEAK_IMPORT_ATTRIBUTE\n' "$availability_var"
      else
        printf '#elif MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_%s\n' \
          "$(underscored "$deprecation_version")"
        printf '    #define %s    DEPRECATED_ATTRIBUTE\n' "$availability_var"
      fi
      printf '#else\n'
      if [ -z "$deprecation_version" ] \
         || {
              [ -z "$3" ] && [ "$version" = "$deprecation_version" ]
            }; then
        printf '    #define %s\n' "$availability_var"
      else
        printf '    #define %s    %s\n' \
          "$availability_var" "$availability_var_def"
      fi
      printf '#endif\n\n'
    }

    MACRO_END='#endif  /* __AVAILABILITYMACROS__ */'
    substituteInPlace EXTERNAL_HEADERS/AvailabilityMacros.h \
      --replace "$MACRO_END" \
        "$( for d_v in $(versions 10.13 10.14.1); do
              availability_block "$d_v"
              availability_block "$d_v" "$d_v" '10.0'
              for a_v in $(versions "$d_v" 10.14.1); do
                if [ "$a_v" = "$d_v" ]; then
                  continue
                fi
                availability_block "$a_v" "$d_v"
              done
            done
            printf '%s' "$MACRO_END"
        )"

    internal_av_dep_block() {
      version=$1
      deprecation_version=$2
      printf '            #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_%s    __attribute__((availability(macosx,introduced=%s,deprecated=%s)))\n' \
        "$(underscored "$version")" "$(underscored "$deprecation_version")" \
        "$version" "$deprecation_version"
      printf '            #if __has_feature(attribute_availability_with_message)\n'
      printf '                #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_%s_MSG(_msg)    __attribute__((availability(macosx,introduced=%s,deprecated=%s,message=_msg)))\n' \
        "$(underscored "$version")" "$(underscored "$deprecation_version")" \
        "$version" "$deprecation_version"
      printf '            #else\n'
      printf '                #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_%s_MSG(_msg)    __attribute__((availability(macosx,introduced=%s,deprecated=%s)))\n' \
        "$(underscored "$version")" "$(underscored "$deprecation_version")" \
        "$version" "$deprecation_version"
      printf '            #endif\n'
    }

    internal_av_NA_block() {
      version=$1
      printf '            #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_NA_MSG(_msg)    __attribute__((availability(macosx,introduced=%s)))\n' \
        "$(underscored "$version")" "$version"
      printf '            #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_NA    __attribute__((availability(macosx,introduced=%s)))\n' \
        "$(underscored "$version")" "$version"
    }

    av_int_X_dep_10_12_4() {
      version=$1
      printf '                #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_10_12_4_MSG(_msg)    __attribute__((availability(macosx,introduced=%s,deprecated=10.12.4)))' \
        "$(underscored "$version")" "$version"
    }

    substituteInPlace EXTERNAL_HEADERS/AvailabilityInternal.h \
      --replace '        #define __MAC_OS_X_VERSION_MAX_ALLOWED __MAC_10_12_4' \
                '        #define __MAC_OS_X_VERSION_MAX_ALLOWED __MAC_10_14_1'

    for a_v in $(versions 10.0 10.12.4); do
      version_anchor=$(av_int_X_dep_10_12_4 "$a_v")
      substituteInPlace EXTERNAL_HEADERS/AvailabilityInternal.h \
        --replace "$version_anchor" \
          "$( printf '%s\n' "$version_anchor"
              printf '            #endif\n'
              for d_v in $(versions 10.13 10.14.1); do
                internal_av_dep_block "$a_v" "$d_v"
              done | sed '$d'
          )"
    done

    AV_INT_10_12_4_DEP_NA='            #define __AVAILABILITY_INTERNAL__MAC_10_12_4_DEP__MAC_NA                __attribute__((availability(macosx,introduced=10.12.4)))'
    substituteInPlace EXTERNAL_HEADERS/AvailabilityInternal.h \
      --replace "$AV_INT_10_12_4_DEP_NA" \
        "$( printf '%s\n' "$AV_INT_10_12_4_DEP_NA"
            for a_v in $(versions 10.13 10.14.1); do
              printf '            #define __AVAILABILITY_INTERNAL__MAC_%s    __attribute__((availability(macosx,introduced=%s)))\n' \
                "$(underscored "$a_v")" "$a_v"
              for d_v in $(versions "$a_v" 10.14.1); do
                internal_av_dep_block "$a_v" "$d_v"
              done
              internal_av_NA_block "$a_v"
            done
        )"

    max_allowed_block() {
      v=$(underscored "$1")
      printf '        #if __MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_%s\n' "$v"
      printf '            #define __AVAILABILITY_INTERNAL__MAC_%s        __AVAILABILITY_INTERNAL_UNAVAILABLE\n' "$v"
      printf '        #elif __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_%s\n' "$v"
      printf '            #define __AVAILABILITY_INTERNAL__MAC_%s        __AVAILABILITY_INTERNAL_WEAK_IMPORT\n' "$v"
      printf '        #else\n'
      printf '            #define __AVAILABILITY_INTERNAL__MAC_%s        __AVAILABILITY_INTERNAL_REGULAR\n' "$v"
      printf '        #endif\n'
    }

    REVERSE_VERSIONS='10.14.1 10.14 10.13.4 10.13.2 10.13.1 10.13'
    MAX_ALLOWED_10_12_4='        #if __MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_12_4'
    substituteInPlace EXTERNAL_HEADERS/AvailabilityInternal.h \
      --replace "$MAX_ALLOWED_10_12_4" \
        "$( for max_allowed_version in $REVERSE_VERSIONS; do
              max_allowed_block "$max_allowed_version"
            done
            printf '%s\n' "$MAX_ALLOWED_10_12_4"
        )"

    conditional_int_av_dep_block() {
      d_v=$1
      printf '        #if __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_%s\n' \
        "$(underscored "$d_v")"
      for a_v in $(versions 10.0 "$d_v"); do
        printf '            #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_%s              __AVAILABILITY_INTERNAL_DEPRECATED\n' \
          "$(underscored "$a_v")" "$(underscored "$d_v")"
        printf '            #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_%s_MSG(_msg)    __AVAILABILITY_INTERNAL_DEPRECATED_MSG(_msg)\n' \
          "$(underscored "$a_v")" "$(underscored "$d_v")"
      done
      printf '        #else\n'
      for a_v in $(versions 10.0 "$d_v"); do
        printf '            #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_%s              __AVAILABILITY_INTERNAL__MAC_%s\n' \
          "$(underscored "$a_v")" "$(underscored "$d_v")" \
          "$(underscored "$a_v")"
        printf '            #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_%s_MSG(_msg)    __AVAILABILITY_INTERNAL__MAC_%s\n' \
          "$(underscored "$a_v")" "$(underscored "$d_v")" \
          "$(underscored "$a_v")"
      done
      printf '        #endif\n'
    }

    AV_INT_10_0_DEP_NA='        #define __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_NA             __AVAILABILITY_INTERNAL__MAC_10_0'
    substituteInPlace EXTERNAL_HEADERS/AvailabilityInternal.h \
      --replace "$AV_INT_10_0_DEP_NA" \
        "$( for v in $(versions 10.13 10.14.1); do
              conditional_int_av_dep_block "$v"
            done
            printf '%s\n' "$AV_INT_10_0_DEP_NA"
        )"

    AV_INT_NA_DEP_NA='        #define __AVAILABILITY_INTERNAL__MAC_NA_DEP__MAC_NA               __AVAILABILITY_INTERNAL_UNAVAILABLE'
    substituteInPlace EXTERNAL_HEADERS/AvailabilityInternal.h \
      --replace "$AV_INT_NA_DEP_NA" \
        "$( for v in $(versions 10.13 10.14.1); do
              printf '        #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_NA             __AVAILABILITY_INTERNAL__MAC_%s\n' \
                "$(underscored "$v")" "$(underscored "$v")"
              printf '        #define __AVAILABILITY_INTERNAL__MAC_%s_DEP__MAC_NA_MSG(_msg)   __AVAILABILITY_INTERNAL__MAC_%s\n' \
                "$(underscored "$v")" "$(underscored "$v")"
            done
            printf '%s\n' "$AV_INT_NA_DEP_NA"
        )"

    patchShebangs .
  '' + lib.optionalString stdenv.isAarch64 ''
    # iig is closed-sourced, we don't have it
    # create an empty file to the header instead
    # this line becomes: echo "" > $@; echo --header ...
    substituteInPlace iokit/DriverKit/Makefile \
      --replace '--def $<' '> $@; echo'
  '';

  PLATFORM = "MacOSX";
  SDKVERSION = "10.13";
  CC = "${stdenv.cc.targetPrefix or ""}cc";
  CXX = "${stdenv.cc.targetPrefix or ""}c++";
  MIG = "mig";
  MIGCOM = "migcom";
  STRIP = "${stdenv.cc.bintools.targetPrefix or ""}strip";
  NM = "${stdenv.cc.bintools.targetPrefix or ""}nm";
  UNIFDEF = "unifdef";
  DSYMUTIL = "dsymutil";
  HOST_OS_VERSION = "10.10";
  HOST_CC = "${buildPackages.stdenv.cc.targetPrefix or ""}cc";
  HOST_FLEX = "flex";
  HOST_BISON = "bison";
  HOST_GM4 = "m4";
  MIGCC = "cc";
  ARCHS = arch;
  ARCH_CONFIGS = arch;

  NIX_CFLAGS_COMPILE = "-Wno-error";

  preBuild = let macosVersion =
    "10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9 10.10 10.10.2 10.10.3 10.11 10.11.2 10.11.3 10.11.4 10.12 10.12.1 10.12.2 10.12.4 10.13 10.13.1 10.13.2 10.13.4"
    + lib.optionalString stdenv.isAarch64 " 10.14 10.15 11.0";
   in ''
    # This is a bit of a hack...
    mkdir -p sdk/usr/local/libexec

    cat > sdk/usr/local/libexec/availability.pl <<EOF
      #!$SHELL
      if [ "\$1" == "--macosx" ]; then
        echo ${macosVersion}
      elif [ "\$1" == "--ios" ]; then
        echo 2.0 2.1 2.2 3.0 3.1 3.2 4.0 4.1 4.2 4.3 5.0 5.1 6.0 6.1 7.0 7.1 8.0 8.1 8.2 8.3 8.4 9.0 9.1 9.2 9.3 10.0 10.1 10.2 10.3 11.0 11.1 11.2 11.3 11.4
      fi
    EOF
    chmod +x sdk/usr/local/libexec/availability.pl

    export SDKROOT_RESOLVED=$PWD/sdk
    export HOST_SDKROOT_RESOLVED=$PWD/sdk

    export BUILT_PRODUCTS_DIR=.
    export DSTROOT=$out
  '';

  buildFlags = lib.optional headersOnly "exporthdrs";
  installTargets = lib.optional headersOnly "installhdrs";

  postInstall = lib.optionalString headersOnly ''
    mv $out/usr/include $out

    (cd BUILD/obj/EXPORT_HDRS && find -type f -exec install -D \{} $out/include/\{} \;)

    # TODO: figure out why I need to do this
    cp libsyscall/wrappers/*.h $out/include
    install -D libsyscall/os/tsd.h $out/include/os/tsd.h
    cp EXTERNAL_HEADERS/AssertMacros.h $out/include
    cp EXTERNAL_HEADERS/Availability*.h $out/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/
    cp -r EXTERNAL_HEADERS/corecrypto $out/include

    # Build the mach headers we crave
    export SRCROOT=$PWD/libsyscall
    export DERIVED_SOURCES_DIR=$out/include
    export SDKROOT=$out
    export OBJROOT=$PWD
    export BUILT_PRODUCTS_DIR=$out
    libsyscall/xcodescripts/mach_install_mig.sh

    # Get rid of the System prefix
    mv $out/System/* $out/
    rmdir $out/System

    # Get buried headers
    mv libsyscall/wrappers/{libproc/libproc,spawn/spawn}.h $out/include

    # TODO: do I need this?
    mv $out/internal_hdr/include/mach/*.h $out/include/mach

    # Get rid of some junk lying around
    rm -r $out/internal_hdr $out/usr $out/local

    # Add some symlinks
    ln -s $out/Library/Frameworks/System.framework/Versions/B \
          $out/Library/Frameworks/System.framework/Versions/Current
    ln -s $out/Library/Frameworks/System.framework/Versions/Current/PrivateHeaders \
          $out/Library/Frameworks/System.framework/Headers

    # IOKit (and possibly the others) is incomplete,
    # so let's not make it visible from here...
    mkdir $out/Library/PrivateFrameworks
    mv $out/Library/Frameworks/IOKit.framework $out/Library/PrivateFrameworks

    # Private header needed by system_cmds
    mkdir $privateHeaders
    mv libsyscall/wrappers/spawn/spawn_private.h $privateHeaders
  '';

  appleHeaders = builtins.readFile (./. + "/headers-${arch}.txt");
} // lib.optionalAttrs headersOnly {
  HOST_CODESIGN = "echo";
  HOST_CODESIGN_ALLOCATE = "echo";
  LIPO = "echo";
  LIBTOOL = "echo";
  CTFCONVERT = "echo";
  CTFMERGE = "echo";
  CTFINSERT = "echo";
  NMEDIT = "echo";
  IIG = "echo";
})
