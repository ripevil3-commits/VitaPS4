# VitaPS4

Experimental effort to port **Vita3K** into a native PS4 homebrew application for jailbroken consoles running GoldHEN.

> **Status:** bootstrap / feasibility work. This repository does **not** yet contain a working Vita3K PS4 port or a tested emulator PKG.

## Source being ported

- Vita3K fork: https://github.com/ripevil3-commits/Vita3K
- Official Vita3K project: https://github.com/Vita3K/Vita3K

## First milestone: validate the PS4 build path

From a Linux/WSL shell with OpenOrbis and Clang/LLD installed, set `OO_PS4_TOOLCHAIN` to the root of the installed toolchain, then run:

```sh
export OO_PS4_TOOLCHAIN=/path/to/OpenOrbis-PS4-Toolchain
bash scripts/check-openorbis-env.sh
bash scripts/build-smoke.sh
```

The smoke test builds a tiny C application and packages it as `out/VitaPS4-SMOKE-v00.01.pkg`. It prints a startup message, waits five seconds, and exits. It is **not Vita3K** and does not emulate any games. The packaging script copies the OpenOrbis sample icon and runtime modules from your local SDK into the generated package; those files are not stored in this repository. Keep the generated package private and install it only on a test console with GoldHEN.

The smoke build and package have **not** yet been run or tested on hardware by this repository. Passing the environment checker alone is not proof of a working PKG.

## Porting roadmap

1. Validate cross-compilation and PKG creation with the smoke test.
2. Add a PS4-specific CMake target without breaking Vita3K's existing desktop/Android targets.
3. Replace the desktop Qt front end with a PS4-friendly front end and controller handling.
4. Port dependencies and runtime assumptions for the PS4 ABI.
5. Bring up a compatible graphics backend. Vulkan is a major blocker because PS4 needs a working PS4 GPU driver path.
6. Integrate Vita3K core, then package and test on real hardware.

See the [source audit and blocker list](docs/PORTING_AUDIT.md) and the [reference-port analysis of PS4SX2 and M33](docs/REFERENCE_PORTS.md).

## Licensing

Vita3K is GPLv2-licensed. Check the license of every dependency and preserve the relevant notices when modifying or distributing a port. The repository does not include game files, firmware, keys, or the locally supplied OpenOrbis runtime modules; do not redistribute packages that contain SDK/runtime files unless their licenses explicitly permit it.
