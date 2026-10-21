#!/usr/bin/env bash
# Check prerequisites for scripts/build-smoke.sh. This does not compile Vita3K.
set -euo pipefail

SDK="${OO_PS4_TOOLCHAIN:-${OPENORBIS:-}}"
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
        printf 'MISS path: %s\n' "$1"
        missing=1
    fi
}

printf 'Checking host build tools...\n'
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
    "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tests/smoke/main.c"; do
    need_path "$path"
done

if [ "$missing" -ne 0 ]; then
    printf '\nPrerequisite check failed. Fix the missing tools/paths before building.\n' >&2
    exit 1
fi
printf '\nPrerequisites look present. Run scripts/build-smoke.sh next; installation and launch still require a real PS4 test.\n'
