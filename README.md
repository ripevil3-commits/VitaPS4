# VitaPS4

Experimental effort to port **Vita3K** into a native PS4 homebrew application for jailbroken consoles running GoldHEN.

> **Status:** bootstrap / feasibility work. This repository does **not** yet contain a working Vita3K PS4 port or a tested emulator PKG.

## Source being ported

- Vita3K fork: https://github.com/ripevil3-commits/Vita3K
- Official Vita3K project: https://github.com/Vita3K/Vita3K

## First milestone: validate the PS4 build path

From a Linux/WSL shell with OpenOrbis and Clang/LLD installed, set `OO_PS4_TOOLCHAIN` to the root of the toolchain, then run:

```sh
export OO_PS4_TOOLCHAIN=/path/to/OpenOrbis-PS4-Toolchain
bash scripts/check-openorbis-env.sh
bash scripts/build-smoke.sh
```

The smoke test builds a tiny C application and attempts to package it as `out/VitaPS4-SMOKE-v00.01.pkg`. It prints a startup message, waits five seconds, and exits. Install it only on a test console with GoldHEN. This is **not Vita3K**, does not emulate any games, and has not yet been built or tested on hardware by this repository.

## Porting roadmap

1. Validate cross-compilation and PKG creation with the smoke test.
2. Add a PS4-specific CMake target without breaking Vita3K's existing desktop/Android targets.
3. Replace the desktop Qt front end with a PS4-friendly front end and controller handling.
4. Port dependencies and runtime assumptions for the PS4 ABI.
5. Bring up a compatible graphics backend. Vulkan is a major blocker because PS4 needs a working PS4 GPU driver path.
6. Integrate Vita3K core, then package and test on real hardware.

See [the source audit and blocker list](docs/PORTING_AUDIT.md).

## Licensing

Vita3K is GPLv2-licensed. Check the license of every dependency and preserve the relevant notices when modifying or distributing a port. The smoke test does not include game files, firmware, keys, or proprietary Sony modules.
