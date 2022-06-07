{ lib, appleDerivation, xcbuildHook, bison, libedit, libresolv, libutil }:

appleDerivation {
  patchPhase = ''
    # NOTE: these hashes must be recalculated for each version change

    # disables:
    # - su ('bsm/audit_session.h' file not found, pam_appl.h comes from OpenPAM)
    # fixes:
    # - find
    # - expr
    # By running the yacc step manually, xcbuild tries to run yacc without an
    # argument and this makes bison (disguised as yacc) error.
    substituteInPlace shell_cmds.xcodeproj/project.pbxproj \
      --replace "FCBA168714A146D000AA698B /* PBXTargetDependency */," "" \
      --replace "expr.y" "expr.c" \
      --replace "getdate.y" "getdate.c" \
      --replace "sourcecode.yacc" "sourcecode.c.c" \
      --replace "/AppleInternal" "$out/AppleInternal"

    # test is usually in /bin but we don't have a /usr/bin to distinguish
    # get rid of permission stuff
    substituteInPlace xcodescripts/install-files.sh \
      --replace 'bin/' 'usr/bin/' \
      --replace "-o root -g wheel -m 0755" "" \
      --replace "-o root -g wheel -m 0644" ""
  '';

  nativeBuildInputs = [ xcbuildHook bison ];

  buildInputs = [ libedit libresolv libutil ];

  NIX_LDFLAGS = "-lresolv";

  preBuild = ''
    mkdir -p "$PWD"/Intermediates/shell_cmds.build/Release/sh.build/DerivedSources

    # Run yacc steps manually, xcbuild runs yacc (bison in disguise) without
    # arguments and it errors because it needs an input file
    for d in expr find; do
      for f in "$d"/*.y; do
        yacc --output-file="''${f/.y/.c}" "$f"
      done
    done
  '';

  # temporary install phase until xcodebuild has "install" support
  installPhase = ''
    for f in Products/Release/*; do
      if [ -f $f ]; then
        install -D $f $out/usr/bin/$(basename $f)
      fi
    done

    export DSTROOT=$out
    export SRCROOT=$PWD
    . xcodescripts/install-files.sh

    mv $out/usr/* $out
    mv $out/private/etc $out
    rmdir $out/usr $out/private
    rm -r $out/AppleInternal # Looks like a bunch of test results we don't need
  '';

  meta = {
    platforms = lib.platforms.darwin;
    maintainers = with lib.maintainers; [ matthewbauer ];
  };
}
