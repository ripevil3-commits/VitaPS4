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

The smoke build and PKG **were successfully created in GitHub Actions** using OpenOrbis v0.5.4. This validates the Linux cross-compile/link/package pipeline for the tiny C test only. The generated PKG was not retained as a downloadable artifact, and the app has **not** been launched on real PS4 hardware. Passing CI is not proof of console runtime compatibility.

## Porting roadmap

1. ✅ Validate cross-compilation and PKG creation with the smoke test in CI.
2. Launch the generated smoke app on a test PS4 with GoldHEN; verify exit behavior and capture logs.
3. Replace the five-second console smoke program with a minimal visible shell and controller input.
4. Add a PS4-specific Vita3K CMake target without breaking desktop/Android targets.
5. Port the minimum dependency set and runtime assumptions for the PS4 ABI.
6. Bring up one compatible renderer path, then incrementally integrate Vita3K core and test on hardware.

See the [source audit and blocker list](docs/PORTING_AUDIT.md) and the [reference-port analysis of PS4SX2 and M33](docs/REFERENCE_PORTS.md).

## Licensing

Vita3K is GPLv2-licensed. Check the license of every dependency and preserve the relevant notices when modifying or distributing a port. The repository does not include game files, firmware, keys, or the locally supplied OpenOrbis runtime modules; do not redistribute packages that contain SDK/runtime files unless their licenses explicitly permit it.
