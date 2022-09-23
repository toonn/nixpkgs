{ stdenv, lib
, fetchFromGitHub , fetchYarnDeps , fixup_yarn_lock
, electron , nodejs , yarn , zip
}:

stdenv.mkDerivation rec {
  pname = "gb-studio";
  version = "3.0.3";

  src = fetchFromGitHub {
    owner = "chrismaltby";
    repo = "gb-studio";
    rev = "v${version}";
    sha256 = "sha256-QqGTUXVlV42Xyiq4wEqgyIWWlcM1JY/L+9k5YcOfomA=";
  };

  yarnDeps = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-5IGYDcp6+tcU2rIGFLr9bIMSRsxFFm9FqFPzjvZWMV0=";
  };

  nativeBuildInputs = [ yarn zip ];
  buildInputs = [ nodejs ];

  patchPhase = ''
    runHook prePatch

    substituteInPlace webpack.cli.config.js --replace \
      'mode: "development"' 'mode: "production"'

    runHook postPatch
  '';

  buildPhase = ''
    runHook preBuild

    ###
    # Add a fake `git` so we don't need to keep `.git` in the source
    ###

    mkdir fake-bin

    cat >fake-bin/git <<'EOF'
    #!${stdenv.shell} -e

    case "$@" in
      "describe --always"| \
      "rev-list --max-count=1 --no-merges --abbrev-commit HEAD")
        echo ${src.rev};;
      *) echo "INVALID fake git arguments: $@" 1>&2;;
    esac
    EOF

    chmod +x fake-bin/*
    export PATH="$PWD/fake-bin''${PATH:+:$PATH}"

    ###
    # Set up the environment to use Yarn
    ###

    # Yarn writes temporary files to $HOME. Copied from mkYarnModules.
    export HOME=$NIX_BUILD_TOP/yarn_home

    # Make yarn install packages from our offline cache, not the registry
    yarn config --offline set yarn-offline-mirror ${yarnDeps}

    # Fixup "resolved"-entries in yarn.lock to match our offline cache
    ${fixup_yarn_lock}/bin/fixup_yarn_lock yarn.lock

    yarn install --offline --frozen-lockfile --ignore-scripts --no-progress \
      --non-interactive

    # The `electron` module needs to be able to use the electron executable
    echo ${lib.getBin electron}/bin/electron >node_modules/electron/path.txt

    # patchShebangs node_modules/

    ###
    # Build into `./out/`, suppress formatting.
    ###
    yarn --offline make:cli | cat

  '' + lib.optionalString stdenv.isDarwin ''
    yarn --offline make:mac | cat
  '' + ''

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,libexec}
    # TODO: Installing production dependencies should be the proper way to do
    #       this but `electron` is needed for the CLI and not part of them.
    # yarn install --offline --frozen-lockfile --ignore-scripts --no-progress \
    #   --non-interactive --production \
    #   --modules-folder=$out/libexec/node_modules
    # Install run-time dependencies alongside the CLI
    cp --parents -pnPR node_modules/{electron,vm2} $out/libexec
    cp --parents -pnPR out/cli/gb-studio-cli.js $out/libexec
    chmod +x $out/libexec/out/cli/gb-studio-cli.js
    ln -s ../libexec/out/cli/gb-studio-cli.js $out/bin/gb-studio-cli

  '' + lib.optionalString stdenv.isDarwin ''
    mkdir -p $out/Applications
    mv out/'GB Studio-darwin-x64/GB Studio.app' $out/Applications
  '' + ''

    runHook postInstall
  '';

  meta = with lib; {
    description = "A quick and easy to use drag and drop retro game creator"
      + " for your favourite handheld video game system";
    longDescription = ''
      GB Studio is a quick and easy to use retro adventure game creator for
      Game Boy available for Mac, Linux and Windows. For more information see
      the GB Studio site

      GB Studio consists of an Electron game builder application and a C based
      game engine using GBDK, music is provided by GBT Player

      * Easy to Use: Drag and drop game creator with simple, no progamming
                     knowledge required, visual scripting. Multiple game genres
                     supported.
      * Write Music: Inbuilt editor makes writing music easy. With both piano
                     roll and tracker modes.
      * Build ROMs: Create real ROM files and play on any GB emulator. Export
                    for web with great mobile controls, upload to Itch.io and
                    share your game with the world.
    '';
    homepage = "https://www.gbstudio.dev/";
    downloadPage = "https://chrismaltby.itch.io/gb-studio";
    license = licenses.mit;
    maintainers = with maintainers; [ toonn ];
    platforms = [ "x86_64-darwin" ];
  };
}
