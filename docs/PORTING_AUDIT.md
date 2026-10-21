# Vita3K → PS4: source audit

**Audit date:** 2026-10-21  
**Status:** source audit plus successful automated smoke-app and SDL2 shell builds/packages on 2026-10-21. No PS4 hardware launch test has been performed.

## Findings confirmed in the source

| Area | Current source | Porting impact |
|---|---|---|
| Build language | Root `CMakeLists.txt` sets C++23 and requires CMake 3.22 or newer. | Cross toolchain and its C++ runtime must support the language features used by the current source. |
| CPU emulation | `external/CMakeLists.txt` builds Dynarmic with the A32 frontend enabled; `vita3k/cpu/CMakeLists.txt` links the `cpu` library to Dynarmic and Capstone. | The guest CPU is ARMv7/A32; the PS4 host is x86-64. Preserve the existing JIT architecture where possible, then prove it builds and runs under the PS4 ABI. |
| Front end | `vita3k/CMakeLists.txt` adds `gui-qt` and creates a desktop executable on non-Android platforms. | A PS4 build needs a separate entry point/front end; simply cross-compiling the default desktop target is not sufficient. |
| Rendering | `vita3k/renderer/CMakeLists.txt` includes both OpenGL and Vulkan source files. | The PS4 target needs explicit renderer selection. Vulkan is promising only if the target runtime exposes a compatible driver; ordinary PC Vulkan loader assumptions cannot be taken for granted. |
| Platform libraries | `external/CMakeLists.txt` builds or links SDL, FFmpeg, cubeb, Boost, fmt/spdlog, Dynarmic, and other dependencies. | Each dependency must be cross-built or disabled/replaced, and platform-specific sockets, threading, filesystem, audio and input calls must be checked. |
| Submodules | `.gitmodules` declares many required external repositories; `external/CMakeLists.txt` checks that they are present. | A reproducible build must initialize/pin all required submodules and avoid silently using empty folders. |

Source links:
- [Vita3K CMake root](https://github.com/ripevil3-commits/Vita3K/blob/master/CMakeLists.txt)
- [Vita3K external dependencies](https://github.com/ripevil3-commits/Vita3K/blob/master/external/CMakeLists.txt)
- [Vita3K app target and front ends](https://github.com/ripevil3-commits/Vita3K/blob/master/vita3k/CMakeLists.txt)
- [CPU emulation target](https://github.com/ripevil3-commits/Vita3K/blob/master/vita3k/cpu/CMakeLists.txt)
- [Renderer target](https://github.com/ripevil3-commits/Vita3K/blob/master/vita3k/renderer/CMakeLists.txt)

## What the working PS4 ports tell us

The public [Crema](https://github.com/iHaiDeeZ/Crema) and [DolphinPS4](https://github.com/iHaiDeeZ/DolphinPS4) projects show that a substantial emulator can be brought to PS4, but this is not a generic “turn CMake into PKG” process.

Their build documentation/scripts use an OpenOrbis-based cross toolchain, custom runtime/sysroot work, platform-specific front ends, and a Mesa/RADV path adapted for PS4 GPU submission. Their Cemu configuration explicitly disables desktop GUI/input/audio backends and enables Vulkan. Those pieces are references for architecture and testing strategy—not files that can be copied over and expected to work unchanged with Vita3K.

[PS4SX2](https://github.com/iHaiDeeZ/PS4SX2) adds another useful reference: it separates the PS4 build, link and package stages, has a dedicated PS4 Makefile and link target, and stages `param.sfo` and assets before generating a GP4 and PKG. Its build also relies on a PS4-adapted runtime and RADV path, not just stock desktop Vulkan. The practical implications and file-level references are in [REFERENCE_PORTS.md](REFERENCE_PORTS.md).

References:
- [Crema build configuration](https://github.com/iHaiDeeZ/Crema/blob/main/scripts/configure-cemu.sh)
- [Crema PS4 toolchain integration](https://github.com/iHaiDeeZ/Crema/tree/main/toolchain)
- [DolphinPS4 build guide](https://github.com/iHaiDeeZ/DolphinPS4/blob/main/BUILDING.md)
- [DolphinPS4 Mesa port](https://github.com/iHaiDeeZ/DolphinPS4/tree/main/port/mesa)
- [PS4SX2 PS4 build driver](https://github.com/iHaiDeeZ/PS4SX2/blob/main/ps4/build-ps4.sh)
- [PS4SX2 package helper](https://github.com/iHaiDeeZ/PS4SX2/blob/main/ps4/make-pkg.sh)

## Blockers, in order

### 0. Prove the toolchain and package pipeline

✅ Build and package both a tiny native PS4 app and an SDL2 menu/controller shell using OpenOrbis v0.5.4 — completed in CI. Remaining: install the locally rebuilt shell package with GoldHEN on a test PS4, confirm video output and controller handling, and collect logs. The repository's smoke builder and SDL2 shell builder ran successfully in GitHub Actions against OpenOrbis v0.5.4. Both C sources compiled, linked to ELF files, converted to eboot, and packaged as PKGs. The CI job does not upload either package, and no real-console launch has yet been verified.

### 1. Verify the shell on real hardware

A separate SDL2 shell prototype now draws a menu and reacts to input events; its PKG has been generated successfully in CI. It is not yet verified on-console, and its “Start Vita3K” action is explicitly a placeholder because the emulator core is not linked.

### 2. Add a PS4-specific build target

Add an explicit CMake option/platform condition for PS4. Do not change the normal Windows/Linux/macOS/Android targets. Exclude desktop-only Qt integrations, auto-updaters, Discord presence and OS-specific windowing from the PS4 target where they do not apply.

### 3. Bring up the integrated application shell

Create a PS4 entry point and front end that can draw a basic screen, read DualShock 4 input, handle exit/navigation, and read/write files under the app's writable data directory. This should be tested before linking the full emulator core.

### 4. Port dependencies and runtime assumptions

Cross-build the minimal dependency set first. Confirm C++23 support, threading, dynamic code generation, executable-memory permissions, exception/unwind handling, allocation limits, filesystem paths, network calls and audio output under the actual PS4 runtime. Remove or replace unsupported dependencies deliberately rather than masking linker errors.

### 5. Graphics backend

Vita3K currently compiles both OpenGL and Vulkan renderer code. Decide on one PS4-supported path and gate the other renderer out at configure time. This is likely the largest integration task because GPU submission and driver/runtime expectations are platform-specific.

### 6. Integrate Vita3K and package

Only after the app shell, CPU/JIT and renderer can be built separately should we link Vita3K core modules, add game-library/config paths, stage required assets, generate `sce_sys/param.sfo`, and package a PKG. Final status requires a real console test and logs.

## Non-goals for the first milestone

- Do not claim game compatibility before the emulator starts and loads a test title.
- Do not put game files, firmware, or keys in this repository. The smoke builder copies the standard OpenOrbis sample icon and runtime modules from the user's local toolchain into the locally generated smoke package; it does not keep those files in Git. Do not redistribute a generated package containing runtime files unless their licenses explicitly permit it.
- Do not advertise a PKG as working before a fresh build and real-device launch test.
