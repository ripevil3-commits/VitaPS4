#!/usr/bin/env bash
# Build and package the visible SDL2 shell (still no Vita3K core).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec env VITAPS4_APP=shell bash "$HERE/build-ps4-app.sh" "$@"
