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

The smoke test builds a tiny C application and packages it as `out/VitaPS4-SMOKE-v00.01.pkg`. It prints a startup message, waits five seconds, and exits. The SDL2 shell prototype builds as `out/VitaPS4-SHELL-v00.01.pkg`; it draws a simple menu and handles SDL keyboard/joystick events, with a placeholder action because the Vita3K core is not linked yet. Neither app emulates games. Both targets were built and packaged in CI against OpenOrbis v0.5.4; neither has been launched on real PS4 hardware. The packaging script copies the OpenOrbis sample icon and runtime modules from your local SDK into generated packages; those files are not stored in this repository. Keep generated packages private and install them only on a test console with GoldHEN.

The smoke and SDL2 shell PKGs were successfully created in GitHub Actions using OpenOrbis v0.5.4. This validates the compile/link/package pipeline for those two test apps only. The generated PKGs were not retained as downloadable artifacts, and neither app has been launched on real PS4 hardware. Passing CI is not proof of console runtime compatibility.

## Porting roadmap

1. ✅ Build and package a native smoke test plus SDL2 shell in CI using OpenOrbis v0.5.4.
2. Launch the shell on a test PS4 with GoldHEN; verify video output, controller input, menu navigation, and clean exit.
3. Add an explicit PS4 CMake path in a feature branch of Vita3K, keeping desktop/Android targets unchanged.
4. Cross-build the minimum CPU/JIT and support libraries, with desktop Qt and Discord features gated off for PS4.
5. Bring up Vita3K's renderer with an actual PS4-compatible Vulkan/runtime path.
6. Integrate core initialization and legally obtained user content only after the shell, JIT, and renderer have been tested.

See the [source audit and blocker list](docs/PORTING_AUDIT.md) and the [reference-port analysis of PS4SX2 and M33](docs/REFERENCE_PORTS.md).

## Licensing

Vita3K is GPLv2-licensed. Check the license of every dependency and preserve the relevant notices when modifying or distributing a port. The repository does not include game files, firmware, keys, or the locally supplied OpenOrbis runtime modules; do not redistribute packages that contain SDK/runtime files unless their licenses explicitly permit it.
