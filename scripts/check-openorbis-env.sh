#!/usr/bin/env bash
# Check prerequisites for the native PS4 app build. This does not compile Vita3K.
set -euo pipefail

SDK="${OO_PS4_TOOLCHAIN:-${OPENORBIS:-}}"
APP_KIND="${VITAPS4_APP:-smoke}"
if [ -z "$SDK" ]; then
    echo "Set OO_PS4_TOOLCHAIN to the root of your OpenOrbis toolchain." >&2
    exit 2
fi
if [ ! -d "$SDK" ]; then
    echo "OpenOrbis directory not found: $SDK" >&2
    exit 2
fi
SDK="$(cd "$SDK" && pwd)"
export OO_PS4_TOOLCHAIN="$SDK"
export PATH="$SDK/bin/linux:$PATH"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$APP_KIND" in
    smoke) SOURCE="$ROOT/tests/smoke/main.c" ;;
    shell) SOURCE="$ROOT/tests/shell/main.c" ;;
    *)
        echo "Unknown VITAPS4_APP='$APP_KIND' (expected smoke or shell)." >&2
        exit 2
        ;;
esac

missing=0
need_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        printf 'OK   command: %s (%s)\n' "$1" "$(command -v "$1")"
    else
        printf 'MISS command: %s\n' "$1"
        missing=1
    fi
}
need_path() {
    if [ -e "$1" ]; then
        printf 'OK   path: %s\n' "$1"
    else
        printf 'MISS path: %s\n' "$1" >&2
        missing=1
    fi
}

printf 'Checking host build tools for %s...\n' "$APP_KIND"
for cmd in clang ld.lld; do need_cmd "$cmd"; done

printf '\nChecking OpenOrbis build and package files at %s...\n' "$SDK"
for path in \
    "$SDK/link.x" \
    "$SDK/include/orbis/libkernel.h" \
    "$SDK/lib/crt1.o" \
    "$SDK/bin/linux/create-fself" \
    "$SDK/bin/linux/create-gp4" \
    "$SDK/bin/linux/PkgTool.Core" \
    "$SDK/samples/SDL2/sce_sys/icon0.png" \
    "$SDK/samples/piglet/sce_sys/about/right.sprx" \
    "$SDK/samples/piglet/sce_module/libc.prx" \
    "$SDK/samples/piglet/sce_module/libSceFios2.prx" \
    "$SOURCE"; do
    need_path "$path"
done
if [ "$APP_KIND" = shell ]; then
    need_path "$SDK/include/SDL2/SDL.h"
    need_path "$SDK/lib/libSDL2.a"
fi

if [ "$missing" -ne 0 ]; then
    printf '\nPrerequisite check failed. Fix the missing tools/paths before building.\n' >&2
    exit 1
fi
printf '\nPrerequisites look present. Run scripts/build-%s.sh; console launch still needs a real PS4 test.\n' "$APP_KIND"
