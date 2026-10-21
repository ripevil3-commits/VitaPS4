#!/usr/bin/env bash
# Build one native PS4 application, produce eboot.bin and package a local fake-PKG.
# VITAPS4_APP=smoke (default) builds the toolchain smoke test.
# VITAPS4_APP=shell builds the SDL2 menu/controller shell; neither target includes Vita3K.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_KIND="${VITAPS4_APP:-smoke}"
SDK="${OO_PS4_TOOLCHAIN:-${OPENORBIS:-}}"
if [[ -z "$SDK" ]]; then
    echo "Set OO_PS4_TOOLCHAIN to the OpenOrbis toolchain root." >&2
    exit 2
fi
if [[ ! -d "$SDK" ]]; then
    echo "OpenOrbis directory not found: $SDK" >&2
    exit 2
fi
SDK="$(cd "$SDK" && pwd)"
TOOLS="$SDK/bin/linux"
BUILD_DIR="${VITAPS4_BUILD_DIR:-$ROOT/build/$APP_KIND}"
OUT_DIR="${VITAPS4_OUT_DIR:-$ROOT/out}"

case "$APP_KIND" in
    smoke)
        SOURCE="$ROOT/tests/smoke/main.c"
        BINARY="smoke"
        TITLE="VitaPS4 Smoke Test"
        TITLE_ID="VITA00001"
        CONTENT_LABEL="VITAPS4SMOKE0000"
        OUTPUT_NAME="VitaPS4-SMOKE-v00.01.pkg"
        LINK_LIBS=(-lc -lkernel -lc++)
        ;;
    shell)
        SOURCE="$ROOT/tests/shell/main.c"
        BINARY="vita_shell"
        TITLE="VitaPS4 Native Shell"
        TITLE_ID="VITA00002"
        CONTENT_LABEL="VITAPS4SHELL0000"
        OUTPUT_NAME="VitaPS4-SHELL-v00.01.pkg"
        # This follows the dependency set from the official OpenOrbis SDL2 sample.
        LINK_LIBS=(-lc -lkernel -lc++ -lSceUserService -lSceVideoOut -lSceAudioOut -lScePad -lSceSysmodule -lSceFreeType -lSDL2)
        ;;
    *)
        echo "Unknown VITAPS4_APP='$APP_KIND' (expected smoke or shell)." >&2
        exit 2
        ;;
esac

mkdir -p "$BUILD_DIR" "$OUT_DIR"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
export OO_PS4_TOOLCHAIN="$SDK"
export PATH="$TOOLS:$PATH"

fail=0
need_file() {
    if [[ -f "$1" ]]; then
        printf 'OK   %s\n' "$1"
    else
        printf 'MISS %s\n' "$1" >&2
        fail=1
    fi
}
need_exec() {
    if [[ -x "$1" ]]; then
        printf 'OK   %s\n' "$1"
    else
        printf 'MISS executable: %s\n' "$1" >&2
        fail=1
    fi
}

echo "[build:$APP_KIND] checking OpenOrbis toolchain"
for item in \
    "$SDK/link.x" \
    "$SDK/include/orbis/libkernel.h" \
    "$SDK/lib/crt1.o" \
    "$SDK/samples/SDL2/sce_sys/icon0.png" \
    "$SDK/samples/piglet/sce_sys/about/right.sprx" \
    "$SDK/samples/piglet/sce_module/libc.prx" \
    "$SDK/samples/piglet/sce_module/libSceFios2.prx" \
    "$SOURCE"; do
    need_file "$item"
done
if [[ "$APP_KIND" == shell ]]; then
    need_file "$SDK/include/SDL2/SDL.h"
    need_file "$SDK/lib/libSDL2.a"
fi
for item in "$TOOLS/create-fself" "$TOOLS/create-gp4" "$TOOLS/PkgTool.Core"; do
    need_exec "$item"
done
for cmd in clang ld.lld; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf 'OK   command: %s (%s)\n' "$cmd" "$(command -v "$cmd")"
    else
        printf 'MISS command: %s (install LLVM/Clang or add it to PATH)\n' "$cmd" >&2
        fail=1
    fi
done
if [[ "$fail" -ne 0 ]]; then
    echo "[build:$APP_KIND] prerequisites missing; no build was attempted." >&2
    exit 1
fi

rm -f "$BUILD_DIR/main.o" "$BUILD_DIR/$BINARY.elf" "$BUILD_DIR/$BINARY.oelf" "$BUILD_DIR/eboot.bin"
echo "[build:$APP_KIND] compiling $SOURCE"
clang --target=x86_64-pc-freebsd12-elf -fPIC -funwind-tables \
    -isysroot "$SDK" -isystem "$SDK/include" \
    -c "$SOURCE" -o "$BUILD_DIR/main.o"

echo "[build:$APP_KIND] linking the PS4 ELF"
ld.lld -m elf_x86_64 -pie --script "$SDK/link.x" --eh-frame-hdr \
    -L"$SDK/lib" "$BUILD_DIR/main.o" -o "$BUILD_DIR/$BINARY.elf" \
    "${LINK_LIBS[@]}" "$SDK/lib/crt1.o"

echo "[build:$APP_KIND] creating eboot.bin"
(
    cd "$BUILD_DIR"
    "$TOOLS/create-fself" "-in=$BUILD_DIR/$BINARY.elf" "-out=$BUILD_DIR/$BINARY.oelf" \
        --eboot "eboot.bin" --paid 0x3800000000000011
)
if [[ ! -s "$BUILD_DIR/eboot.bin" ]]; then
    echo "create-fself did not produce $BUILD_DIR/eboot.bin" >&2
    exit 1
fi

VERSION="00.01"
CONTENT_ID="IV0000-${TITLE_ID}_00-${CONTENT_LABEL}"
STAGE="$BUILD_DIR/stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/sce_sys/about" "$STAGE/sce_module"
cp "$BUILD_DIR/eboot.bin" "$STAGE/eboot.bin"
cp "$SDK/samples/SDL2/sce_sys/icon0.png" "$STAGE/sce_sys/icon0.png"
cp "$SDK/samples/piglet/sce_sys/about/right.sprx" "$STAGE/sce_sys/about/right.sprx"
cp "$SDK/samples/piglet/sce_module/libc.prx" "$STAGE/sce_module/libc.prx"
cp "$SDK/samples/piglet/sce_module/libSceFios2.prx" "$STAGE/sce_module/libSceFios2.prx"

SFO="$STAGE/sce_sys/param.sfo"
"$TOOLS/PkgTool.Core" sfo_new "$SFO"
set_entry() {
    "$TOOLS/PkgTool.Core" sfo_setentry "$SFO" "$1" --type "$2" --maxsize "$3" --value "$4" >/dev/null
}
set_entry APP_TYPE Integer 4 1
set_entry APP_VER Utf8 8 "$VERSION"
set_entry ATTRIBUTE Integer 4 0
set_entry CATEGORY Utf8 4 gd
set_entry CONTENT_ID Utf8 48 "$CONTENT_ID"
set_entry DOWNLOAD_DATA_SIZE Integer 4 0
set_entry SYSTEM_VER Integer 4 0
set_entry TITLE Utf8 128 "$TITLE"
set_entry TITLE_ID Utf8 12 "$TITLE_ID"
set_entry VERSION Utf8 8 "$VERSION"

echo "[build:$APP_KIND] generating package metadata"
(
    cd "$STAGE"
    "$TOOLS/create-gp4" -out pkg.gp4 --content-id="$CONTENT_ID" \
        --files "eboot.bin sce_sys/about/right.sprx sce_sys/param.sfo sce_sys/icon0.png sce_module/libc.prx sce_module/libSceFios2.prx"
    "$TOOLS/PkgTool.Core" pkg_build pkg.gp4 "$OUT_DIR"
)
PKG="$OUT_DIR/$CONTENT_ID.pkg"
if [[ ! -s "$PKG" ]]; then
    echo "Package was not created where expected: $PKG" >&2
    exit 1
fi
cp "$PKG" "$OUT_DIR/$OUTPUT_NAME"
echo "[build:$APP_KIND] build succeeded: $OUT_DIR/$OUTPUT_NAME"
if [[ "$APP_KIND" == shell ]]; then
    echo "[build:$APP_KIND] this is a visible SDL2 shell, not a linked Vita3K emulator."
else
    echo "[build:$APP_KIND] this tests the native process startup path, not Vita3K."
fi
echo "[build:$APP_KIND] runtime modules are copied from your local SDK; do not redistribute the generated package unless permitted."
