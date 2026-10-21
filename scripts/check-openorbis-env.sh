#!/usr/bin/env bash
# Check the host tools and OpenOrbis layout used by the PS4 porting work.
# This is a prerequisite check only; it does not compile Vita3K or create a PKG.
set -euo pipefail

OPENORBIS="${OPENORBIS:-/opt/pacbrew/ps4/openorbis}"
CLANG_VER="${CLANG_VER:-21}"
missing=0

need_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        printf 'OK   command: %s\n' "$1"
    else
        printf 'MISS command: %s\n' "$1"
        missing=1
    fi
}

need_file() {
    if [ -e "$1" ]; then
        printf 'OK   path: %s\n' "$1"
    else
        printf 'MISS path: %s\n' "$1"
        missing=1
    fi
}

printf 'Checking host dependencies...\n'
for cmd in cmake ninja git python3 "clang-${CLANG_VER}" "clang++-${CLANG_VER}" "ld.lld-${CLANG_VER}" "llvm-ar-${CLANG_VER}"; do
    need_cmd "$cmd"
done

printf '\nChecking OpenOrbis toolchain at %s...\n' "$OPENORBIS"
for path in \
    "$OPENORBIS/cmake/ps4.cmake" \
    "$OPENORBIS/link.x" \
    "$OPENORBIS/include" \
    "$OPENORBIS/lib/crt1.o" \
    "$OPENORBIS/bin/linux/create-fself" \
    "$OPENORBIS/bin/linux/create-gp4" \
    "$OPENORBIS/bin/linux/PkgTool.Core"; do
    need_file "$path"
done

if [ "$missing" -ne 0 ]; then
    printf '\nEnvironment check failed. Install/fix the missing host tools or set OPENORBIS and CLANG_VER.\n' >&2
    exit 1
fi

printf '\nEnvironment layout looks ready for the next milestone. No binary was built by this check.\n'
