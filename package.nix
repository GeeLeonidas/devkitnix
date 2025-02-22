{ stdenv
, name
, src
, autoPatchelfHook
, ncurses6
, zsnes
}:

stdenv.mkDerivation {
  inherit name src;
  nativeBuildInputs = [
    autoPatchelfHook
  ];
  buildInputs = [
    stdenv.cc.cc
    ncurses6
    zsnes
  ];
  buildPhase = "true";
  installPhase = ''
    mkdir -p $out

    find . -type d | grep "/lib$" | xargs -i cp -rn {} $out
    find . -type d | grep "/libexec$" | xargs -i cp -rn {} $out

    find . -type d | grep "/include$" | xargs -i cp -rn {} $out
    find . -type d | grep "/lib/pkgconfig$" | xargs -i cp -rn {} $out/lib
    find . -type d | grep "/lib/cmake$" | xargs -i cp -rn {} $out/lib
    find . -type d | grep "/share/aclocal$" | xargs -i cp -rn {} $out/share

    find . -type d | grep "/bin$" | xargs -i cp -rn {} $out

    find . -type d | grep "/doc$" | xargs -i cp -rn {} $out

    rm -rf $out/pacman
  '';
}