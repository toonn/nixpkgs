{ lib, appleDerivation, xcbuildHook, llvmPackages, makeWrapper }:

appleDerivation {
  nativeBuildInputs = [ xcbuildHook makeWrapper ];

  postPatch = ''
    makeWrapper ${llvmPackages.clang}/bin/clang $out/bin/clang-cpp --add-flags "--driver-mode=cpp"
    substituteInPlace rpcgen/rpc_main.c \
      --replace "/usr/bin/cpp" "$out/bin/clang-cpp"
  '';

  # Workaround build failure on -fno-common toolchains:
  #   duplicate symbol '_btype_2' in:args.o pr_comment.o
  NIX_CFLAGS_COMPILE = "-fcommon";

  # temporary install phase until xcodebuild has "install" support
  installPhase = ''
    for f in Products/Release/*; do
      if [ -f $f ]; then
        install -D $f $out/bin/$(basename $f)
      fi
    done

    for n in 1; do
      mkdir -p $out/share/man/man$n
      install */*.$n $out/share/man/man$n
    done
  '';

  meta = {
    platforms = lib.platforms.darwin;
    maintainers = with lib.maintainers; [ matthewbauer ];
  };
}
