{ lib, stdenv, fetchurl, fetchzip, pkgs }:

let
  # This attrset can in theory be computed automatically, but for that to work nicely we need
  # import-from-derivation to work properly. Currently it's rather ugly when we try to bootstrap
  # a stdenv out of something like this. With some care we can probably get rid of this, but for
  # now it's staying here.
  versions = {
    "osx-10.13.6" = {
      inherit (versions."Developer-Tools-9.0") developer_cmds;
      inherit (versions."osx-10.3") IOATABlockStorage;
      inherit (versions."osx-10.3.9") IOSCSIArchitectureModelFamily;
      inherit (versions."osx-10.7.4") Libm;
      "IOUSBFamily-10.8.4" = versions."osx-10.8.4".IOUSBFamily;
      inherit (versions."osx-10.8.5") IOUSBFamily;
      inherit (versions."osx-10.9") basic_cmds libunwind;
      "Libc-10.9.2" = versions."osx-10.9.2".Libc;
      inherit (versions."osx-10.9.4") launchd;
      inherit (versions."osx-10.10") Csu;
      inherit (versions."osx-10.11") architecture Librpcsvc;
      inherit (versions."osx-10.12") IOFWDVComponents
        IOFireWireSerialBusProtocolTransport libclosure;
      inherit (versions."osx-10.13") bootstrap_cmds file_cmds IOAudioFamily
        IOBDStorageFamily IOCDStorageFamily IODVDStorageFamily IOSerialFamily
        libedit Libnotify libresolv objc4 ppp shell_cmds text_cmds;
      inherit (versions."osx-10.13.1") libutil;
      inherit (versions."osx-10.13.2") Libinfo;
      inherit (versions."osx-10.13.4") CommonCrypto copyfile eap8021x hfs
        IOFireWireSBP2 IONetworkingFamily IOStorageFamily Libc libiconv
        libmalloc libplatform libpthread network_cmds;
      inherit (versions."osx-10.13.5") ICU IOFireWireAVC IOFireWireFamily
        libdispatch;
      adv_cmds        = "172";
      configd         = "963.50.8";
      diskdev_cmds    = "593";
      dtrace          = "262.50.12";
      dyld            = "551.4";
      IOGraphics      = "519.20";
      IOHIDFamily     = "1035.70.7";
      IOKitUser       = "1445.71.1";
      libauto         = "187";
      Libsystem       = "1252.50.4";
      mDNSResponder   = "878.70.2";
      PowerManagement = "703.71.1";
      removefile      = "45";
      Security        = "58286.70.7";
      syslog          = "356.70.1";
      system_cmds     = "790.50.6";
      top             = "111.20.1";
      xnu             = "4570.71.2";
    };
    "osx-10.13.5" = {
      ICU              = "59180.0.1";
      IOFireWireAVC    = "423";
      IOFireWireFamily = "472";
      libdispatch      = "913.60.2";
    };
    "osx-10.13.4" = {
      CommonCrypto       = "60118.50.1";
      copyfile           = "146.50.5";
      eap8021x           = "264.50.5";
      hfs                = "407.50.6";
      IOFireWireSBP2     = "428";
      IONetworkingFamily = "124.50.3";
      IOStorageFamily    = "218.50.2";
      Libc               = "1244.50.9";
      libiconv           = "51.50.1";
      libmalloc          = "140.50.6";
      libplatform        = "161.50.1";
      libpthread         = "301.50.1";
      network_cmds       = "543.50.4";
    };
    "osx-10.13.2" = {
      hfs     = "407.30.1"; # Old but current version is missing hfs_mount.h
      Libinfo = "517.30.1";
    };
    "osx-10.13.1" = {
      libutil = "51.20.1";
    };
    "osx-10.13" = {
      bootstrap_cmds     = "98";
      file_cmds          = "272";
      IOAudioFamily      = "206.5";
      IOBDStorageFamily  = "19";
      IOCDStorageFamily  = "58";
      IODVDStorageFamily = "42";
      IOSerialFamily     = "93";
      libedit            = "50";
      Libnotify          = "172";
      libresolv          = "65";
      objc4              = "723";
      ppp                = "847";
      shell_cmds         = "203";
      text_cmds          = "99";
    };
    "osx-10.12.6" = {
      xnu           = "3789.70.16";
      Libsystem     = "1238.60.2";
      removefile    = "45";
      dtrace        = "209.50.12";
    };
    "osx-10.12" = {
      IOFWDVComponents                     = "208";
      IOFireWireSerialBusProtocolTransport = "252";
      libclosure                           = "67";
    };
    "osx-10.11.6" = {
      dtrace        = "168";
      xnu           = "3248.60.10";
      Libsystem     = "1226.10.1";
      removefile    = "41";

      # IOKit contains a set of packages with different versions, so we don't have a general version
      IOKit         = "";

      adv_cmds      = "163";
      system_cmds   = "550.6";
      diskdev_cmds   = "593";
      top           = "108";
    };
    "osx-10.11" = {
      architecture = "268";
      Librpcsvc    = "26";
    };
    "osx-10.10.5" = {
      adv_cmds      = "158";
      CF            = "1153.18";
      Security      = "57031.40.6";
    };
    "osx-10.10" = {
      Csu = "85";
    };
    "osx-10.9.5" = {
      libauto            = "185.5";
      Libsystem          = "1197.1.1";
      Security           = "55471.14.18";
      security_dotmac_tp = "55107.1";
    };
    "osx-10.9.4" = {
      launchd = "842.92.1";
    };
    "osx-10.9.2" = {
      Libc = "997.90.3";
    };
    "osx-10.9" = {
      basic_cmds = "55";
      libunwind  = "35.3";
    };
    "osx-10.8.5" = {
      configd     = "453.19";
      IOUSBFamily = "630.4.5";
    };
    "osx-10.8.4" = {
      IOUSBFamily = "560.4.2";
    };
    "osx-10.7.4" = {
      Libm = "2026";
    };
    "osx-10.6.2" = {
      CarbonHeaders = "18.1";
    };
    "osx-10.5.8" = {
      adv_cmds = "119";
    };
    "osx-10.3.9" = {
      IOSCSIArchitectureModelFamily = "139.0.2"; # Old but most recent version
    };
    "osx-10.3" = {
      IOATABlockStorage = "130.3.1"; # Old but most recent version available
    };
    "Developer-Tools-9.0" = {
      developer_cmds = "66";
    };
    "dev-tools-3.1.3" = {
      bsdmake = "24";
    };
  };

  appleTarballUrl = pname: version:
    "http://www.opensource.apple.com/tarballs/${pname}/${pname}-${version}.tar.gz";

  fetchApple' = pname: version: sha256: let
    # When cross-compiling, fetchurl depends on libiconv, resulting
    # in an infinite recursion without this. It's not clear why this
    # worked fine when not cross-compiling
    fetch = if pname == "libiconv"
      then stdenv.fetchurlBoot
      else fetchurl;
  in fetch {
    url = appleTarballUrl pname version;
    inherit sha256;
  };

  fetchApple = sdkName: sha256: aname: let
    pname = builtins.head (lib.splitString "-" aname);
    version = versions.${sdkName}.${aname};
  in fetchApple' pname version sha256;

  appleDerivation'' = stdenv: pname: version: sdkName: sha256: attrs: stdenv.mkDerivation ({
    inherit pname version;

    src = if attrs ? srcs then null else (fetchApple' pname version sha256);

    enableParallelBuilding = true;

    # In rare cases, APPLE may drop some headers quietly on new release.
    doInstallCheck = attrs ? appleHeaders;
    passAsFile = [ "appleHeaders" ];
    installCheckPhase = ''
      cd $out/include

      result=$(diff -u "$appleHeadersPath" <(find * -type f,l | sort) --label "Listed in appleHeaders" --label "Found in \$out/include" || true)

      if [ -z "$result" ]; then
        echo "Apple header list is matched."
      else
        echo >&2 "\
      Apple header list is inconsistent, please ensure no header file is unexpectedly dropped.
      $result
      "
        exit 1
      fi
    '';

  } // attrs // {
    meta = (with lib; {
      platforms = platforms.darwin;
      license = licenses.apsl20;
    }) // (attrs.meta or {});
  });

  IOKitSpecs = {
    IOATABlockStorage                    = fetchApple "osx-10.13.6" "sha256-6gRCbdnTX9LO9sKWeVUErvjdnj3BBxyOlRpGujaU1nc=";
    IOAudioFamily                        = fetchApple "osx-10.13.6" "sha256-RE+h8DASGR4TvRM3XjIwUwrCKl0aYRqBybXzvs8poNM=";
    IOBDStorageFamily                    = fetchApple "osx-10.13.6" "sha256-KehxMGfnQbzDffTJZWGIxkNTVugaJ5zk6JbJM1oGoE0=";
    IOCDStorageFamily                    = fetchApple "osx-10.13.6" "sha256-3/cdF7PCP8xQQmKmVYlFqYytI2T4AYbR2Qpu5lP2QPM=";
    IODVDStorageFamily                   = fetchApple "osx-10.13.6" "sha256-kXfE1jzPM8tPGvEWnlyBB9Egq0JYo6Kssk8xucxGMvc=";
    IOFWDVComponents                     = fetchApple "osx-10.13.6" "sha256-93NA8NLSSjFxNMibXLpM3rrMBF7wC5Y5dbd0tBF8xUs=";
    IOFireWireAVC                        = fetchApple "osx-10.13.6" "sha256-VK2KYLouoVokRVoAI8wQNbSdr+GVhoR00Unj9c6wiqQ=";
    IOFireWireFamily                     = fetchApple "osx-10.13.6" "sha256-YahZ8fVAwgevD4WlOTX5wWN9rD6ktyvKDiavyyNG8v0=";
    IOFireWireSBP2                       = fetchApple "osx-10.13.6" "sha256-3QhzYNuMae/47ublxqGm3NIzeHDWP3uDLFQSmgNcFUc=";
    IOFireWireSerialBusProtocolTransport = fetchApple "osx-10.13.6" "sha256-FpVTZiSG1rSZ9Od8FxRCEj1WzljvbaXziYpAkBFx+G0=";
    IOGraphics                           = fetchApple "osx-10.13.6" "sha256-/nb8ywP9Pm6F6+biRb0sIcW3+fr3LvO9SlzG5nQyLaY=";
    IOHIDFamily                          = fetchApple "osx-10.13.6" "sha256-Rlrbx1wHgfcVAmrqWHb33QfMAGMBAX369giTKJVqgI4=";
    IOKitUser                            = fetchApple "osx-10.13.6" "sha256-4pwP/pabkoXt8iRh5UliVq0ThyKv7eyEDB7cBoWNSag=";
    IONetworkingFamily                   = fetchApple "osx-10.13.6" "sha256-MjQ+f4gqB31GAQTusbPVPnY8FzBwrpzYspCpIcPQRkc=";
    IOSCSIArchitectureModelFamily        = fetchApple "osx-10.13.6" "sha256-3b8zRIszBS8FG99uaP5bDDW0k3sLrJlkNKL6S9oR06w=";
    IOSerialFamily                       = fetchApple "osx-10.13.6" "sha256-bMa4VBuaPwbtjtsy1oNUIE0WhuAkTb09phdDMHPCtNU=";
    IOStorageFamily                      = fetchApple "osx-10.13.6" "sha256-MmnxgkidyNwykmv2OA02d9itxowC5kDavK85fkTAzJM=";
    # There should be an IOStreamFamily project here, but they haven't released it :(
    IOUSBFamily                          = fetchApple "osx-10.13.6" "1znqb6frxgab9mkyv7csa08c26p9p0ip6hqb4wm9c7j85kf71f4j"; # This is from 10.8 :(
    "IOUSBFamily-10.8.4"                 = fetchApple "osx-10.13.6" "sha256-tPovFcXIbftOzPzZb5ivgxl16EJQkHtEW1Ebi/6tdIQ="; # This is even older :(
    # There should be an IOVideo here, but they haven't released it :(
  };

  IOKitSrcs = lib.mapAttrs (name: value: if lib.isFunction value then value name else value) IOKitSpecs;

in

# darwin package set
self:

let
  macosPackages_11_0_1 = import ./macos-11.0.1.nix { inherit applePackage'; };
  developerToolsPackages_11_3_1 = import ./developer-tools-11.3.1.nix { inherit applePackage'; };

  applePackage' = namePath: version: sdkName: sha256:
    let
      pname = builtins.head (lib.splitString "/" namePath);
      appleDerivation' = stdenv: appleDerivation'' stdenv pname version sdkName sha256;
      appleDerivation = appleDerivation' stdenv;
      callPackage = self.newScope { inherit appleDerivation' appleDerivation; };
    in callPackage (./. + "/${namePath}");

  applePackage = namePath: sdkName: sha256: let
    pname = builtins.head (lib.splitString "/" namePath);
    version = versions.${sdkName}.${pname};
  in applePackage' namePath version sdkName sha256;

  # Only used for bootstrapping. It’s convenient because it was the last version to come with a real makefile.
  adv_cmds-boot = applePackage "adv_cmds/boot.nix" "osx-10.5.8" "102ssayxbg9wb35mdmhswbnw0bg7js3pfd8fcbic83c5q3bqa6c6" {};

in

developerToolsPackages_11_3_1 // macosPackages_11_0_1 // {
    # TODO: shorten this list, we should cut down to a minimum set of bootstrap or necessary packages here.

    inherit (adv_cmds-boot) ps locale;
    architecture    = applePackage "architecture"      "osx-10.13.6"     "1pbpjcd7is69hn8y29i98ci0byik826if8gnp824ha92h90w0fq3" {};
    bootstrap_cmds  = applePackage "bootstrap_cmds"    "osx-10.13.6"     "14xp48h9fij749mn9jdxb41swk24hk9r2f6v3qyqs6s7z2jwlyxi" {};
    bsdmake         = applePackage "bsdmake"           "dev-tools-3.1.3" "11a9kkhz5bfgi1i8kpdkis78lhc6b5vxmhd598fcdgra1jw4iac2" {};
    CarbonHeaders   = applePackage "CarbonHeaders"     "osx-10.6.2"      "1zam29847cxr6y9rnl76zqmkbac53nx0szmqm9w5p469a6wzjqar" {};
    CommonCrypto    = applePackage "CommonCrypto"      "osx-10.13.6"     "sha256-1wqgLyk6Pm3Vu8VJ+Z5Cfh7LB5nvhGRMgbPAgR8AUWc=" {};
    configd         = applePackage "configd"           "osx-10.8.5"      "1gxakahk8gallf16xmhxhprdxkh3prrmzxnmxfvj0slr0939mmr2" {
      Security      = applePackage "Security/boot.nix" "osx-10.9.5"      "1nv0dczf67dhk17hscx52izgdcyacgyy12ag0jh6nl5hmfzsn8yy" {};
    };
    copyfile        = applePackage "copyfile"          "osx-10.13.6"     "sha256-AALgvHYEWs8uJjBG2Se8umVznY2MU2BigSjXe0WesAs=" {};
    Csu             = applePackage "Csu"               "osx-10.13.6"     "0yh5mslyx28xzpv8qww14infkylvc1ssi57imhi471fs91sisagj" {};
    dtrace          = applePackage "dtrace"            "osx-10.12.6"     "0hpd6348av463yqf70n3xkygwmf1i5zza8kps4zys52sviqz3a0l" {};
    dyld            = applePackage "dyld"              "osx-10.13.6"     "sha256-FfhrYvuRx1/N/t/uLvh1lYXUue+e0XV8ro9PE71Y5Rw=" {};
    eap8021x        = applePackage "eap8021x"          "osx-10.13.6"     "0iw0qdib59hihyx2275rwq507bq2a06gaj8db4a8z1rkaj1frskh" {};
    ICU             = applePackage "ICU"               "osx-10.13.6"     "02p9h2jq20g305nrz6n5530m1dk3vqv53lh6yyl1hgayzyjd3f07" {};
    IOKit           = applePackage "IOKit"             "osx-10.11.6"     "0kcbrlyxcyirvg5p95hjd9k8a01k161zg0bsfgfhkb90kh2s8x00" { inherit IOKitSrcs; };
    launchd         = applePackage "launchd"           "osx-10.13.6"     "0w30hvwqq8j5n90s3qyp0fccxflvrmmjnicjri4i1vd2g196jdgj" {};
    libauto         = applePackage "libauto"           "osx-10.9.5"      "17z27yq5d7zfkwr49r7f0vn9pxvj95884sd2k6lq6rfaz9gxqhy3" {};
    Libc            = applePackage "Libc"              "osx-10.13.6"     "sha256-SPG2oC5zJrqIVw8q22QiZtJcUDyILfZsCiTUxN/ZcZA=" {
      # Most recent version to include the `NSSystemDirectories.h` header
      Libc-10_9_2 = fetchzip {
        url    = appleTarballUrl "Libc" "${versions."osx-10.9.2".Libc}";
        sha256 = "1xchgxkxg5288r2b9yfrqji2gsgdap92k4wx2dbjwslixws12pq7";
      };
    };
    libclosure      = applePackage "libclosure"        "osx-10.13.6"     "sha256-jOk1TuP+gfrU0eudZqu4D99oqtca9N8gWUMqLdv48nk=" {};
    libdispatch     = applePackage "libdispatch"       "osx-10.13.6"     "sha256-l4zhkP3yTQZOZikdYBoX6XDj6b7KSNW91nTSJGvSv/0=" {};
    libedit         = applePackage "libedit"           "osx-10.13.6"     "sha256-aAPn4DMvJ4z+D0DCoOmgTXEES19DmhWSODpMpvzqfrA=" {};
    libiconv        = applePackage "libiconv"          "osx-10.13.6"     "0ax3pgjcslik92kmz4wmag4l6d1jnmmlfbimkacpzf3lzxrab2xp" {};
    Libinfo         = applePackage "Libinfo"           "osx-10.13.6"     "sha256-BIEjnS/CY63Vyv44xlThT8CIZRE8jHNCmzAkJjepER4=" {};
    Libm            = applePackage "Libm"              "osx-10.13.6"      "02sd82ig2jvvyyfschmb4gpz6psnizri8sh6i982v341x6y4ysl7" {};
    libmalloc       = applePackage "libmalloc"         "osx-10.13.6"     "sha256-Ky3I3Ox+1no16d0tIz7jEfCl90221bQoqnK8qNHiBcc=" {};
    Libnotify       = applePackage "Libnotify"         "osx-10.13.6"     "sha256-amGQG1y6qCpBWWmqb6mr6KdJytNdaWXiX6so42GGAHs=" {};
    libplatform     = applePackage "libplatform"       "osx-10.13.6"     "sha256-x5IWwXM7E35wQz5ATTVxG+Kn1A9/tXmgBnWtnpubzfg=" {};
    libpthread      = applePackage "libpthread"        "osx-10.13.6"     "sha256-Fk19cVEGaXp8Ghof9RLeBDMAEkIpgsQQa0dTMH07Cug=" {};
    libresolv       = applePackage "libresolv"         "osx-10.13.6"     "sha256-Mu5mRmmcG1oapTqgwzx7l7/Oh90nRX6/VmfDeNpJdz0=" {};
    Libsystem       = applePackage "Libsystem"         "osx-10.12.6"     "1082ircc1ggaq3wha218vmfa75jqdaqidsy1bmrc4ckfkbr3bwx2" {};
    libutil         = applePackage "libutil"           "osx-10.13.6"     "sha256-VhwMYOVlC7ZR9V4dRvf+L+pIlBHPCLGm58PvoH1npGg=" {};
    libunwind       = applePackage "libunwind"         "osx-10.13.6"     "0miffaa41cv0lzf8az5k1j1ng8jvqvxcr4qrlkf3xyj479arbk1b" {};
    mDNSResponder   = applePackage "mDNSResponder"     "osx-10.13.6"     "sha256-zdAxccoF8W6ph7uh+LDEhH0wNSg+oPX6Ct519k7IPtU=" {};
    objc4           = applePackage "objc4"             "osx-10.13.6"     "1zj2wmbilx4b29kc26a06cifasl6la5vl210bz6wy21f38xx8miz" {};
    ppp             = applePackage "ppp"               "osx-10.13.6"     "1vgiq099hdqi61zhjk43snmjp4hd58fa79xbr3m3s4x8an3fr1ih" {};
    removefile      = applePackage "removefile"        "osx-10.12.6"     "0jzjxbmxgjzhssqd50z7kq9dlwrv5fsdshh57c0f8mdwcs19bsyx" {};
    xnu             = if stdenv.isx86_64 then
      applePackage "xnu"                               "osx-10.13.6"     "1k4hyh0fn7zaggsalk9sykznachkpyvglzg3vax1alrlyk5j3ikx" {}
    else macosPackages_11_0_1.xnu;
    hfs             = applePackage "hfs"               "osx-10.13.2"     "sha256-OXuwJt3FibFpqwJ+SKD1u9OiuRFNLt9AEZWrg/u72XY=" {}; # Old but current version does not contain the headers we need
    Librpcsvc       = applePackage "Librpcsvc"         "osx-10.13.6"     "sha256-UzwmQ2RtfRLaDc9Yk8EFd/m2wdhkCWdpC7TnmCjjjv8=" {};
    adv_cmds        = applePackage "adv_cmds"          "osx-10.11.6"    "12gbv35i09aij9g90p6b3x2f3ramw43qcb2gjrg8lzkzmwvcyw9q" {};
    basic_cmds      = applePackage "basic_cmds"        "osx-10.13.6"     "0hvab4b1v5q2x134hdkal0rmz5gsdqyki1vb0dbw4py1bqf0yaw9" {};
    developer_cmds  = applePackage "developer_cmds"    "osx-10.13.6"     "sha256-mdbE708yWT35N6QtUEAMFwVCR+h1q4z7O/Dy3hmpCGA=" {};
    diskdev_cmds    = applePackage "diskdev_cmds"      "osx-10.11.6"     "1ssdyiaq5m1zfy96yy38yyknp682ki6bvabdqd5z18fa0rv3m2ar" {
      macosPackages_11_0_1 = macosPackages_11_0_1;
    };
    network_cmds    = if stdenv.isx86_64 then
      applePackage "network_cmds"                      "osx-10.13.6"     "sha256-HyAId1QNnlx++K403VugmfMLRW33uj3nSkhbZ+GHfzw=" {}
    else macosPackages_11_0_1.network_cmds;
    file_cmds       = applePackage "file_cmds"         "osx-10.13.6"     "sha256-Wy78Slobyt8UQNx5rFTfl6mRa94pJs+JFyroNPvkD6k=" {};
    shell_cmds      = applePackage "shell_cmds"        "osx-10.13.6"     "sha256-lx5lWvjfS34+m56sE3Y5ptJXlPc5JJhZkajGcRC+UHk=" {};
    syslog          = applePackage "syslog"            "osx-10.13.6"     "sha256-EwFTtTDMtiTtiR6Aht0igbMcu5SioiC56i8JRljYyZ0=" {};
    system_cmds     = applePackage "system_cmds"       "osx-10.11.6"     "1h46j2c5v02pkv5d9fyv6cpgyg0lczvwicrx6r9s210cl03l77jl" {};
    text_cmds       = applePackage "text_cmds"         "osx-10.13.6"     "1f93m7dd0ghqb2hwh905mjhzblyfr7dwffw98xhgmv1mfdnigxg0" {};
    top             = applePackage "top"               "osx-10.11.6"     "0i9120rfwapgwdvjbfg0ya143i29s1m8zbddsxh39pdc59xnsg5l" {};
    PowerManagement = applePackage "PowerManagement"   "osx-10.13.6"     "sha256-6WBIKuwBYVg6oFwx+AiZXujfh7FVXsCVM+Fa5CvWCWA=" {};

    # `configdHeaders` can’t use an override because `pkgs.darwin.configd` on aarch64-darwin will
    # be replaced by SystemConfiguration.framework from the macOS SDK.
    configdHeaders  = applePackage "configd"           "osx-10.8.5"      "1gxakahk8gallf16xmhxhprdxkh3prrmzxnmxfvj0slr0939mmr2" {
      headersOnly = true;
      Security    = null;
    };
    hfsHeaders      = pkgs.darwin.hfs.override { headersOnly = true; };
    libresolvHeaders= pkgs.darwin.libresolv.override { headersOnly = true; };

    Security        = applePackage "Security/boot.nix" "osx-10.13.6"      "0gphjzfm28p1cxgp112cn033jmsxla1adqg1qh9i8p5hhlzli2vk" {};
} // (
  # Resort to the SDK for missing headers
  let apple_sdk = pkgs.darwin.apple_sdk.override {
        inherit fetchurl;      python3 = pkgs.python3Minimal;
        inherit (stdenv.__bootPackages) pbzx;
        inherit (stdenv.__bootPackages.darwin) darwin-stubs print-reexports;
      };
  in ({ xpc = apple_sdk.libs.xpc;

      } // lib.optionalAttrs stdenv.hostPlatform.isx86_64 {
       configd = apple_sdk.frameworks.SystemConfiguration;
      })
)
