#!/usr/bin/env bash
# Compatibility entry point: build and package only the native process smoke test.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec env VITAPS4_APP=smoke bash "$HERE/build-ps4-app.sh" "$@"
