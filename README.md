# VitaPS4

Experimental effort to port **Vita3K** into a native PS4 homebrew application for jailbroken consoles running GoldHEN.

> **Status:** bootstrap / feasibility work. This repository does **not** yet contain a working Vita3K PS4 port or a tested emulator PKG.

## Source being ported

- Vita3K fork: https://github.com/ripevil3-commits/Vita3K
- Official Vita3K project: https://github.com/Vita3K/Vita3K

## Native PS4 test apps

From a Linux/WSL shell with OpenOrbis and Clang/LLD installed, set `OO_PS4_TOOLCHAIN` to the root of the installed toolchain. Build the tiny process smoke test:

```sh
export OO_PS4_TOOLCHAIN=/path/to/OpenOrbis-PS4-Toolchain
bash scripts/check-openorbis-env.sh
bash scripts/build-smoke.sh
```

Build the visible SDL2 menu/controller shell separately:

```sh
VITAPS4_APP=shell bash scripts/check-openorbis-env.sh
bash scripts/build-shell.sh
```

The smoke package is written to `out/VitaPS4-SMOKE-v00.01.pkg`. The shell package is written to `out/VitaPS4-SHELL-v00.01.pkg`. Both targets compiled, linked, and packaged successfully in GitHub Actions against OpenOrbis v0.5.4. The shell draws a simple menu and handles SDL keyboard/joystick events, but its “Start Vita3K” action is a placeholder because the emulator core is not linked.

Neither package has been launched on real PS4 hardware, and neither package is a Vita3K emulator. The CI job deliberately does not upload the generated PKGs: the package stage includes runtime module files from the local OpenOrbis SDK. Keep locally generated packages private and do not redistribute SDK/runtime files unless their licenses explicitly allow it.

## Porting roadmap

1. ✅ Build and package a native smoke test plus SDL2 shell in CI using OpenOrbis v0.5.4.
2. Launch the shell on a test PS4 with GoldHEN; verify video output, controller input, menu navigation, and clean exit.
3. Add an explicit PS4 CMake path in a feature branch of Vita3K, keeping desktop/Android targets unchanged.
4. Cross-build the minimum CPU/JIT and support libraries, with desktop Qt and Discord features gated off for PS4.
5. Bring up Vita3K's renderer with an actual PS4-compatible Vulkan/runtime path.
6. Integrate core initialization and user-owned game content only after the shell, JIT, and renderer have been tested.

See the [source audit and blocker list](docs/PORTING_AUDIT.md), the [reference-port analysis of PS4SX2 and M33](docs/REFERENCE_PORTS.md), and the [Vita3K core integration map](docs/CORE_INTEGRATION_MAP.md).

## Licensing

Vita3K is GPLv2-licensed. Check the license of every dependency and preserve the relevant notices when modifying or distributing a port. The repository does not include game files, firmware, keys, or the locally supplied OpenOrbis runtime modules.
