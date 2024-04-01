# with import <nixpkgs> { };

{ lib
, stdenv
, fetchFromGitHub
, platformio
, python3
, git
}:


let
  platformioBundled = platformio;
in
stdenv.mkDerivation rec {
  pname = "meshtasticd";
  version = "2.3.3.8187fa7";

  src = fetchFromGitHub {
    owner = "meshtastic";
    repo = "firmware";
    rev = "v${version}";
    # hash = lib.fakeHash;
    hash = "sha256-oP6wmzo4qp8sFusWVOYL+FRL1C+iny3G/d0cS+CrSD8=";
  };

  nativeBuildInputs = [
    python3
    platformioBundled
    git
  ];

  buildPhase = ''
    ./bin/build-native.sh

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
