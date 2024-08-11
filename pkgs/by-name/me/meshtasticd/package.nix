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
  version = "2.4.1.394e0e1";

  src = fetchFromGitHub {
    owner = "meshtastic";
    repo = "firmware";
    rev = "v${version}";
    hash = "sha256-siwuH4WpWpJyax9PN6zKxEoUtLhseaoGwnx5VkeMt1s=";
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
    runHook preBuild
    set -e

    export VERSION=${version}
    export SHORT_VERSION=$(bin/buildinfo.py short)

    pio run --environment native

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out $out/bin
    cp .pio/build/native/program $out/bin/meshtasticd
    cp bin/config-dist.yaml $out/config_base.yaml

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    timeout 1 $out/bin/meshtasticd | grep '//\ E S H T /\ S T / C' >/dev/null

    runHook postInstallCheck
  '';

  # patchelf complains when it finds the ESP32 binaries which are run by the portduino "emulator"
  dontPatchELF = true;

  dontFixup = true; # TODO figure out why dontPatchELF dowsn't stop patchelf from running (and failing)

  meta = with lib; {
    description = "Allows using a LoRa module/HAT connected to a local SPI port to act as a meshtastic device";
    changelog = "https://github.com/platformio/platformio-core/releases/tag/v${version}";
    homepage = "https://meshtastic.org/docs/software/linux-native/";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ jhollowe ];
    platforms = platforms.linux;
    mainProgram = "meshtasticd";
  };
}
