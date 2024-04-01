# with import <nixpkgs> { };

{ lib
, stdenv
, fetchFromGitHub
, platformio
, python3
, git
, libgpiod
, pkg-config
, cacert
}:


let
  platformioBundled = platformio;
in
stdenv.mkDerivation rec {
  pname = "meshtasticd";
  version = "2.3.3.8187fa7";

  src = fetchFromGitHub {
    # owner = "meshtastic";
    owner = "jhollowe-forks"; # TODO remove once done testing
    repo = "firmware";
    rev = "v${version}";
    # hash = lib.fakeHash;
    hash = "sha256-oP6wmzo4qp8sFusWVOYL+FRL1C+iny3G/d0cS+CrSD8=";
  };

  # used only during build
  nativeBuildInputs = [
    python3
    platformioBundled
    # git
    pkg-config
    libgpiod
    cacert # required for SSL certs used by git when pulling HTTPS repos for platformio
  ];

  # used during runtime
  buildInputs = [
  ];

  patches = [
    ./include_gpiod.patch
  ];

  buildPhase = ''
    set -e

    cat platformio.ini

    export VERSION=${version}
    export SHORT_VERSION=$(bin/buildinfo.py short)


    export GPIOD_INCLUDE=${libgpiod.outPath}/include
    env | sort

    pio run --environment native
    # echo GCC
    # echo | gcc -E -Wp,-v -
    # echo G++
    # echo | g++ -E -Wp,-v -

    mkdir -p $out
    cp -r release/* $out
  '';

  meta = with lib; {
    description = "Allows using a LoRa module/HAT connected to a local SPI port to act as a meshtastic device";
    changelog = "https://github.com/platformio/platformio-core/releases/tag/v${version}";
    homepage = "https://github.com/librtlsdr/librtlsdr";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ jhollowe ];
    platforms = platforms.linux;
  };
}
