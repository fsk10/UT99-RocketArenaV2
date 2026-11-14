#!/bin/bash
# Builds RocketArenaV2.u with the UCC from a local UT 469 install.
# The build runs in ./build (a private copy of the needed engine files), so the
# UT install itself is never modified.
#
#   ./build.sh            build
#   ./build.sh --setup    (re)create ./build from the UT install first
#   ./build.sh --media    also rebuild RocketArenaV2Media (only when the art changed:
#                         a rebuilt package has a new GUID, so it needs a new name)
set -euo pipefail

UT_DIR="${UT_DIR:-/d/UnrealTournament_469f_RC5}"
PKG="RocketArenaV2"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
SYS="$BUILD/System"

setup() {
    echo "Setting up $BUILD from $UT_DIR"
    rm -rf "$BUILD"
    mkdir -p "$SYS" "$BUILD/Sounds" "$BUILD/Textures"
    local f
    # Editor.dll pulls in most engine DLLs, so take them all except the anticheat ones.
    cp "$UT_DIR"/System/UCC.exe "$UT_DIR"/System/*.dll "$SYS/"
    rm -f "$SYS"/ACE*.dll "$SYS"/NPLoader*.dll
    for f in Core Engine Editor Fire IpDrv UWeb UWindow UBrowser UnrealShare UnrealI UMenu Botpack IpServer UTServerAdmin UTMenu UTBrowser; do
        cp "$UT_DIR/System/$f.u" "$SYS/"
        [ -f "$UT_DIR/System/$f.int" ] && cp "$UT_DIR/System/$f.int" "$SYS/"
    done
    cp "$UT_DIR"/System/*.int "$SYS/" 2>/dev/null || true
    cp "$UT_DIR"/Sounds/*.uax "$BUILD/Sounds/"
    cp "$UT_DIR"/Textures/*.utx "$BUILD/Textures/"
    cp "$ROOT/deps/RocketArenaMedia.u" "$SYS/"

    # Default.ini with our package appended to EditPackages.
    sed -e '/^EditPackages=EpicCustomModels/,/^EditPackages=udemo/d' \
        -e "/^EditPackages=UTBrowser/a EditPackages=RocketArena\nEditPackages=${PKG}Media\nEditPackages=$PKG" \
        "$UT_DIR/System/Default.ini" > "$SYS/Build.ini"
    cp "$SYS/Build.ini" "$SYS/BuildUser.ini"
}

[ "${1:-}" = "--setup" ] || [ ! -f "$SYS/UCC.exe" ] && setup
MEDIA="${PKG}Media"
# Build.ini from an older setup: add the media package before the code package.
grep -q "^EditPackages=$MEDIA" "$SYS/Build.ini" || \
    sed -i "s/^EditPackages=$PKG\r\?$/EditPackages=$MEDIA\n&/" "$SYS/Build.ini"

# The media package is built once and then reused from dist/, so its GUID stays the same.
if [ "${1:-}" = "--media" ] || [ ! -f "$ROOT/dist/$MEDIA.u" ]; then
    BUILD_MEDIA=1
    rm -rf "$BUILD/$MEDIA" "$SYS/$MEDIA.u"
    mkdir -p "$BUILD/$MEDIA"
    cp -r "$ROOT/src/$MEDIA/Classes" "$ROOT/src/$MEDIA/Textures" "$BUILD/$MEDIA/"
else
    BUILD_MEDIA=0
    cp "$ROOT/dist/$MEDIA.u" "$SYS/"
fi

# Fresh copy of the sources; UCC only rebuilds a package that is missing.
# RocketArena is a build-only stub of the original map classes (src/RocketArenaStub).
rm -rf "$BUILD/$PKG" "$SYS/$PKG.u" "$BUILD/RocketArena" "$SYS/RocketArena.u"
mkdir -p "$BUILD/$PKG" "$BUILD/RocketArena"
cp -r "$ROOT/src/$PKG/Classes" "$BUILD/$PKG/"
cp -r "$ROOT/src/RocketArenaStub/Classes" "$BUILD/RocketArena/"

cd "$SYS"
./UCC.exe make -ini=Build.ini -userini=BuildUser.ini -silent 2>&1 | tee "$BUILD/make.log" \
    | grep -E -i "error|warning|Success|Failure|Compiling" || true

if [ ! -f "$SYS/$PKG.u" ]; then
    echo "BUILD FAILED - see build/make.log"
    exit 1
fi
mkdir -p "$ROOT/dist"
cp "$SYS/$PKG.u" "$ROOT/dist/"
[ "$BUILD_MEDIA" = 1 ] && cp "$SYS/$MEDIA.u" "$ROOT/dist/" && echo "Built dist/$MEDIA.u"
cp "$ROOT/src/$PKG.int" "$ROOT/dist/" 2>/dev/null || true
echo "Built dist/$PKG.u"
