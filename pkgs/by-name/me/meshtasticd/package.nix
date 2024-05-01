# with import <nixpkgs> { };

{ lib
, stdenv
, fetchFromGitHub
, platformio
, python3
, git
, libgpiod
, yaml-cpp
, bluez
, pkg-config
, cacert
}:


let
  platformioBundled = platformio;
in
stdenv.mkDerivation rec {
  pname = "meshtasticd";
  version = "2.3.6.7a3570a";

  src = fetchFromGitHub {
    # owner = "meshtastic";
    owner = "jhollowe-forks"; # TODO remove once done testing
    repo = "firmware";
    rev = "v${version}";
    # hash = lib.fakeHash; # TODO remove once done testing
    hash = "sha256-K0kraX2vtQA5QW/r4hSgM83cgsyMjgPFfXhkeXPOaJs=";
  };

  # used only during build
  nativeBuildInputs = [
    python3
    platformioBundled
    pkg-config
    cacert # required for SSL certs used by git when pulling HTTPS repos for platformio

    # libraries needed to compile pio tools/libs
    libgpiod
    yaml-cpp
    bluez
  ];

  # used during runtime
  buildInputs = [
    libgpiod
    yaml-cpp
    bluez
  ];

  patches = [
    ./pio_add_lib_paths.patch
  ];

  postPatch = ''
    substituteInPlace platformio.ini --replace-fail GPIOD_STORE_PATH ${libgpiod.outPath}
    substituteInPlace platformio.ini --replace-fail YAML_CPP_STORE_PATH ${yaml-cpp.outPath}
    substituteInPlace platformio.ini --replace-fail BLUEZ_DEV_STORE_PATH ${bluez.dev.outPath}
    substituteInPlace platformio.ini --replace-fail BLUEZ_STORE_PATH ${bluez.outPath}
  '';

  buildPhase = ''
    set -e

    export VERSION=${version}
    export SHORT_VERSION=$(bin/buildinfo.py short)

    pio run --environment native

    mkdir -p $out/native $out/bin
    cp -r .pio/build/native/* $out/native
    cd $out/bin/ && ln -s ../native/program meshtasticd
  '';

  # patchelf complains when it finds the ESP32 binaries which are run by the portduino "emulator"
  dontPatchELF = true;

  dontFixup = true; # TODO figure out why dontPatchELF dowsn't stop patchelf from running (and failing)

  meta = with lib; {
    description = "Allows using a LoRa module/HAT connected to a local SPI port to act as a meshtastic device";
    changelog = "https://github.com/platformio/platformio-core/releases/tag/v${version}";
    homepage = "https://github.com/librtlsdr/librtlsdr";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ jhollowe ];
    platforms = platforms.linux;
  };
}
