#!/usr/bin/env bash
# Check prerequisites for the native OpenOrbis smoke-test build.
# This only checks the environment; it does not compile Vita3K.
set -euo pipefail

SDK="${OO_PS4_TOOLCHAIN:-${OPENORBIS:-}}"
if [ -z "$SDK" ]; then
    echo "Set OO_PS4_TOOLCHAIN to the root of your OpenOrbis toolchain." >&2
    exit 2
fi

missing=0
need_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        printf 'OK   command: %s\n' "$1"
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

printf 'Checking host tools...\n'
for cmd in clang ld.lld python3; do need_cmd "$cmd"; done

printf '\nChecking OpenOrbis at %s...\n' "$SDK"
for path in \
    "$SDK/link.x" \
    "$SDK/include/orbis/libkernel.h" \
    "$SDK/lib/crt1.o" \
    "$SDK/bin/linux/create-fself" \
    "$SDK/bin/linux/create-gp4" \
    "$SDK/bin/linux/PkgTool.Core"; do
    need_path "$path"
done

if [ "$missing" -ne 0 ]; then
    printf '\nPrerequisite check failed. Fix the missing tools/paths before building.\n' >&2
    exit 1
fi
printf '\nPrerequisites look present. The smoke build and PKG still need to be run and tested.\n'
