#!/usr/bin/env bash
# Experimental Vita3K PS4 build + local PKG packaging.
# Requires a prepared PS4 sysroot/toolchain, PS4-built dependencies, SDL3, and a matching static RADV Vulkan loader.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK="${OO_PS4_TOOLCHAIN:-${OPENORBIS:-}}"
PS4_TOOLCHAIN_BIN="${PS4_TOOLCHAIN_BIN:-$HOME/xemups4/toolchain/bin}"
PS4_SYSROOT="${PS4_SYSROOT:-$HOME/xemups4-build/sysroot}"
RUNTIME_INCLUDES="${VITA3K_PS4_RUNTIME_INCLUDE_DIRS:-}"
RUNTIME_LIBS="${VITA3K_PS4_RUNTIME_LIBRARIES:-}"
WSI_SOURCE="${VITA3K_PS4_WSI_SOURCE:-}"
ORBIS_KIT_DIR="${VITA3K_PS4_ORBIS_KIT_DIR:-}"
MESA_SRC="${VITA3K_PS4_MESA_SRC:-}"
MESA_BUILD="${VITA3K_PS4_MESA_BUILD:-}"
VULKAN_HEADERS_DIR="${VITA3K_PS4_VULKAN_HEADERS_DIR:-}"
VULKAN_LOADER_LIBS="${VITA3K_PS4_VULKAN_LOADER_LIBRARIES:-}"
BUILD_DIR="${VITA3K_PS4_BUILD_DIR:-$ROOT/build-ps4}"
OUT_DIR="${VITA3K_PS4_OUT_DIR:-$ROOT/out}"
PAID="${VITA3K_PS4_PAID:-0x3800000000000035}"
VERSION="${VITA3K_PS4_VERSION:-00.01}"
TITLE_ID="${VITA3K_PS4_TITLE_ID:-VITA00003}"
CONTENT_LABEL="${VITA3K_PS4_CONTENT_LABEL:-VITAPS4EMU000000}"
TITLE="${VITA3K_PS4_TITLE:-Vita3K PS4 Prototype}"

die() {
    printf '[vita3k-ps4] ERROR: %s\n' "$*" >&2
    exit 1
}
need_file() {
    [[ -f "$1" ]] || die "Missing file: $1"
}
need_exec() {
    [[ -x "$1" ]] || die "Missing executable: $1"
}

[[ -n "$SDK" ]] || die "Set OO_PS4_TOOLCHAIN to an OpenOrbis SDK root for create-fself/create-gp4/PkgTool.Core."
[[ -d "$SDK" ]] || die "OpenOrbis SDK directory does not exist: $SDK"
SDK="$(cd "$SDK" && pwd)"
[[ -d "$PS4_SYSROOT" ]] || die "PS4 sysroot not found: $PS4_SYSROOT"
[[ -x "$PS4_TOOLCHAIN_BIN/ps4-cc" ]] || die "Missing PS4 compiler wrapper: $PS4_TOOLCHAIN_BIN/ps4-cc"
[[ -x "$PS4_TOOLCHAIN_BIN/ps4-c++" ]] || die "Missing PS4 compiler wrapper: $PS4_TOOLCHAIN_BIN/ps4-c++"
[[ -n "$RUNTIME_LIBS" ]] || die "Set VITA3K_PS4_RUNTIME_LIBRARIES to the semicolon-separated additional PS4 system/runtime libraries."
[[ -n "$WSI_SOURCE" ]] || die "Set VITA3K_PS4_WSI_SOURCE to an adapted RADV/VideoOut WSI implementation source."
need_file "$WSI_SOURCE"
if [[ -n "$ORBIS_KIT_DIR" ]]; then
    need_file "$ORBIS_KIT_DIR/vkloader/CMakeLists.txt"
    [[ -f "$MESA_SRC/include/vulkan/vulkan_core.h" ]] || die "VITA3K_PS4_MESA_SRC must hold the matching Mesa Vulkan headers."
    [[ -f "$MESA_BUILD/src/amd/vulkan/libvulkan_radeon.a" ]] || die "VITA3K_PS4_MESA_BUILD must hold src/amd/vulkan/libvulkan_radeon.a."
elif [[ -n "$VULKAN_LOADER_LIBS" ]]; then
    [[ -f "$VULKAN_HEADERS_DIR/vulkan/vulkan_core.h" ]] || die "VITA3K_PS4_VULKAN_HEADERS_DIR must hold Vulkan headers built for the selected loader."
else
    die "Provide VITA3K_PS4_ORBIS_KIT_DIR + matching VITA3K_PS4_MESA_SRC/BUILD, or VITA3K_PS4_VULKAN_LOADER_LIBRARIES + VITA3K_PS4_VULKAN_HEADERS_DIR."
fi
need_exec "$SDK/bin/linux/create-fself"
need_exec "$SDK/bin/linux/create-gp4"
need_exec "$SDK/bin/linux/PkgTool.Core"
need_file "$SDK/samples/SDL2/sce_sys/icon0.png"

[[ "$TITLE_ID" =~ ^[A-Z]{4}[0-9]{5}$ ]] || die "TITLE_ID must be four uppercase letters followed by five digits."
[[ "$VERSION" =~ ^[0-9]{2}\.[0-9]{2}$ ]] || die "VERSION must use format XX.YY."

export PS4_TOOLCHAIN_BIN PS4_SYSROOT OO_PS4_TOOLCHAIN="$SDK"
mkdir -p "$OUT_DIR" "$BUILD_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"

echo "[vita3k-ps4] configure (experimental; using the linked RADV/VideoOut display WSI)"
cmake -S "$ROOT" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$ROOT/cmake/ps4-wrapper.cmake" \
    -DVITA3K_PS4=ON \
    -DUSE_DISCORD_RICH_PRESENCE=OFF \
    -DUSE_LTO=NEVER \
    -DBoost_ROOT="$PS4_SYSROOT" \
    -DCMAKE_PREFIX_PATH="$PS4_SYSROOT" \
    -DVITA3K_PS4_RUNTIME_INCLUDE_DIRS="$RUNTIME_INCLUDES" \
    -DVITA3K_PS4_RUNTIME_LIBRARIES="$RUNTIME_LIBS" \
    -DVITA3K_PS4_WSI_SOURCE="$WSI_SOURCE" \
    -DVITA3K_PS4_ORBIS_KIT_DIR="$ORBIS_KIT_DIR" \
    -DVITA3K_PS4_MESA_SRC="$MESA_SRC" \
    -DVITA3K_PS4_MESA_BUILD="$MESA_BUILD" \
    -DVITA3K_PS4_VULKAN_HEADERS_DIR="$VULKAN_HEADERS_DIR" \
    -DVITA3K_PS4_VULKAN_LOADER_LIBRARIES="$VULKAN_LOADER_LIBS"

echo "[vita3k-ps4] compile"
cmake --build "$BUILD_DIR" --target vita3k --parallel "${JOBS:-2}"

ELF="$BUILD_DIR/bin/Vita3K"
need_file "$ELF"
STAGE="$BUILD_DIR/pkg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/sce_sys"

echo "[vita3k-ps4] convert ELF to eboot.bin"
(
    cd "$STAGE"
    "$SDK/bin/linux/create-fself" "-in=$ELF" "-out=$STAGE/Vita3K.oelf" --eboot "eboot.bin" --paid "$PAID"
)
need_file "$STAGE/eboot.bin"

echo "[vita3k-ps4] stage immutable assets"
cp "$SDK/samples/SDL2/sce_sys/icon0.png" "$STAGE/sce_sys/icon0.png"
cp -R "$ROOT/data" "$STAGE/data"
cp -R "$ROOT/vita3k/shaders-builtin" "$STAGE/shaders-builtin"
cp -R "$ROOT/vita3k/icons" "$STAGE/icons"
cp "$ROOT/COPYING.txt" "$STAGE/COPYING.txt"

echo "[vita3k-ps4] create param.sfo"
CONTENT_ID="IV0000-${TITLE_ID}_00-${CONTENT_LABEL}"
SFO="$STAGE/sce_sys/param.sfo"
"$SDK/bin/linux/PkgTool.Core" sfo_new "$SFO"
set_entry() {
    "$SDK/bin/linux/PkgTool.Core" sfo_setentry "$SFO" "$1" --type "$2" --maxsize "$3" --value "$4" >/dev/null
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

echo "[vita3k-ps4] build local PKG"
(
    cd "$STAGE"
    "$SDK/bin/linux/create-gp4" -out pkg.gp4 --content-id="$CONTENT_ID" --path .
    "$SDK/bin/linux/PkgTool.Core" pkg_build pkg.gp4 "$OUT_DIR"
)
PKG="$OUT_DIR/$CONTENT_ID.pkg"
need_file "$PKG"
cp "$PKG" "$OUT_DIR/Vita3K-PS4-Prototype-v$VERSION.pkg"

echo "[vita3k-ps4] package created: $OUT_DIR/Vita3K-PS4-Prototype-v$VERSION.pkg"
echo "[vita3k-ps4] This build was not tested on a real PS4; package creation is not proof of emulator compatibility."
