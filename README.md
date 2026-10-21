# VitaPS4

Experimental effort to port **Vita3K** into a native PS4 homebrew application for jailbroken consoles running GoldHEN.

> **Status:** bootstrap / feasibility work. This repository does **not** yet contain a working Vita3K PS4 port or a tested PKG.

## Source being ported

- Vita3K fork: https://github.com/ripevil3-commits/Vita3K
- Official Vita3K project: https://github.com/Vita3K/Vita3K

## Current engineering focus

1. Validate the PS4 cross-compilation and packaging toolchain with a minimal app.
2. Add a PS4-specific build target without breaking existing Vita3K targets.
3. Replace the desktop Qt front end with a PS4-friendly front end and controller handling.
4. Port and test dependencies on the PS4 runtime.
5. Bring up graphics. Vita3K has both OpenGL and Vulkan renderer code; PS4 Vulkan requires a compatible PS4 GPU driver path and is a major blocker.
6. Integrate Vita3K core, then package and test on real hardware.

See [the source audit and blocker list](docs/PORTING_AUDIT.md).

## Build host

The intended cross-build host is Linux or WSL2. Current Vita3K source uses CMake and C++23, so the compiler and C++ standard library must be compatible with that requirement. The PS4 examples in Crema/DolphinPS4 use an OpenOrbis-based toolchain and a custom runtime/sysroot.

Run the environment check from a Linux/WSL shell:

```sh
bash scripts/check-openorbis-env.sh
```

This only checks prerequisites; it does not build Vita3K.

## Licensing

Vita3K is GPLv2-licensed. Check the license of every dependency and preserve the relevant notices when modifying or distributing a port. No game files, firmware, keys, or proprietary Sony modules are included in this repository.
