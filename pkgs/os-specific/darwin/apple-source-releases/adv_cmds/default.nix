{ lib, appleDerivation, xcbuild, flex, libutil
, ncurses, xpc
}:

appleDerivation {
  patchPhase = ''
    substituteInPlace adv_cmds.xcodeproj/project.pbxproj \
      --replace "lex.l" "lex.yy.c" \
      --replace "scan.l" "scan.yy.c" \
      --replace "sourcecode.lex" "sourcecode.c.c" \
      --replace "parse.y" "y.tab.c" \
      --replace "yacc.y" "y.tab.c" \
      --replace "sourcecode.yacc" "sourcecode.c.c" \
      --replace 'libl.a' 'libfl.la' \
      --replace '/usr/lib/libtermcap.dylib' 'libncurses.dylib'
  '';

  preBuild = ''
    # Run flex and yacc steps manually, xcbuild runs lex (flex in disguise) and
    # yacc (bison in disguise) without arguments and they error because they
    # need an input file
    for d in colldef mklocale; do
      pushd "$d"
      for f in *.y; do
        yacc -y -d "$f"
      done
      for f in *.l; do
        flex --header-file="''${f/.l/.yy.h}" --outfile="''${f/.l/.yy.c}" "$f"
      done
      popd
    done
  '';

  # pkill requires special private headers that are unavailable in
  # NixPkgs. These ones are needed:
  # From XPC:
  #  - xpc/xpxc.h
  # From libplatform/private
  #  - os/base_private.h
  #  - _simple.h
  # These headers aren't difficult to get but the next one that's missing is
  # sysmon.h and the only reference online is "private" SDK for macOS 10.10.
  # Maybe something Apple used to ship but no longer does?
  # We disable it here for now. TODO: build pkill inside adv_cmds
  buildPhase = ''
    runHook preBuild

    targets=$(xcodebuild -list \
                | awk '/Targets:/{p=1;print;next} p&&/^\s*$/{p=0};p' \
                | tail -n +2 | sed 's/^[ \t]*//' \
                | grep -v -e Desktop -e Embedded -e pkill -e pgrep )

    for i in $targets; do
      xcodebuild SYMROOT=$PWD/Products OBJROOT=$PWD/Intermediates -target $i
    done
  '';

  # temporary install phase until xcodebuild has "install" support
  installPhase = ''
    for f in Products/Release/*; do
      if [ -f $f ]; then
        install -D $f $out/bin/$(basename $f)
      fi
    done

    # from variant_links.sh
    # ln -s $out/bin/pkill $out/bin/pgrep
    # ln -s $out/share/man/man1/pkill.1 $out/share/man/man1/pgrep.1
  '';

  nativeBuildInputs = [ xcbuild ];
  buildInputs = [ flex libutil ncurses xpc ];

  meta = {
    platforms = lib.platforms.darwin;
    maintainers = with lib.maintainers; [ matthewbauer ];
  };
}
