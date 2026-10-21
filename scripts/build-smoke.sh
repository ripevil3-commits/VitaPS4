#!/usr/bin/env bash
# Build a tiny native PS4 app and package it. This does NOT build Vita3K.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
BUILD_DIR="${VITAPS4_BUILD_DIR:-$ROOT/build/smoke}"
OUT_DIR="${VITAPS4_OUT_DIR:-$ROOT/out}"
mkdir -p "$BUILD_DIR" "$OUT_DIR"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

# The stock OpenOrbis Linux sample uses clang/ld.lld plus these SDK-side tools.
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

echo "[smoke] checking OpenOrbis toolchain"
for item in \
    "$SDK/link.x" \
    "$SDK/include/orbis/libkernel.h" \
    "$SDK/lib/crt1.o" \
    "$SDK/samples/SDL2/sce_sys/icon0.png" \
    "$SDK/samples/piglet/sce_sys/about/right.sprx" \
    "$SDK/samples/piglet/sce_module/libc.prx" \
    "$SDK/samples/piglet/sce_module/libSceFios2.prx" \
    "$ROOT/tests/smoke/main.c"; do
    need_file "$item"
done
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
    echo "[smoke] prerequisites missing; no build was attempted." >&2
    exit 1
fi

rm -f "$BUILD_DIR/main.o" "$BUILD_DIR/smoke.elf" "$BUILD_DIR/smoke.oelf" "$BUILD_DIR/eboot.bin"
echo "[smoke] compiling the C test"
clang --target=x86_64-pc-freebsd12-elf -fPIC -funwind-tables \
    -isysroot "$SDK" -isystem "$SDK/include" \
    -c "$ROOT/tests/smoke/main.c" -o "$BUILD_DIR/main.o"

echo "[smoke] linking the PS4 ELF"
ld.lld -m elf_x86_64 -pie --script "$SDK/link.x" --eh-frame-hdr \
    -L"$SDK/lib" -lc -lkernel -lc++ \
    "$SDK/lib/crt1.o" "$BUILD_DIR/main.o" -o "$BUILD_DIR/smoke.elf"

echo "[smoke] creating eboot.bin"
(
    cd "$BUILD_DIR"
    "$TOOLS/create-fself" "-in=$BUILD_DIR/smoke.elf" "-out=$BUILD_DIR/smoke.oelf" \
        --eboot "eboot.bin" --paid 0x3800000000000011
)
if [[ ! -s "$BUILD_DIR/eboot.bin" ]]; then
    echo "create-fself did not produce $BUILD_DIR/eboot.bin" >&2
    exit 1
fi

TITLE_ID="VITA00001"
VERSION="00.01"
CONTENT_ID="IV0000-${TITLE_ID}_00-VITAPS4SMOKE0000"
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
set_entry TITLE Utf8 128 "VitaPS4 Smoke Test"
set_entry TITLE_ID Utf8 12 "$TITLE_ID"
set_entry VERSION Utf8 8 "$VERSION"

echo "[smoke] generating package metadata"
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
cp "$PKG" "$OUT_DIR/VitaPS4-SMOKE-v00.01.pkg"
echo "[smoke] build succeeded: $OUT_DIR/VitaPS4-SMOKE-v00.01.pkg"
echo "[smoke] install only on a test console with GoldHEN. This tests the native app shell, not Vita3K."
echo "[smoke] keep the locally generated package private; it contains runtime modules copied from your SDK."
