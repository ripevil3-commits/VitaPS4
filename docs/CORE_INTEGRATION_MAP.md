# Vita3K core integration map for PS4

**Source snapshot inspected:** [Vita3K master at `649d7d69b2da2eb55f17233376f861a3a32cf12a`](https://github.com/ripevil3-commits/Vita3K/commit/649d7d69b2da2eb55f17233376f861a3a32cf12a)  
**Date:** 2026-10-21  
**Purpose:** plan the first guarded PS4 build target without breaking the existing desktop and Android targets.

## Important distinction

The standalone `tests/shell/main.c` in this repository uses **SDL2** from OpenOrbis. The current Vita3K frontend uses **SDL3**. The fact that the SDL2 prototype compiles and packages does not mean Vita3K's SDL3 frontend is ported.

## What the source currently does

### Entry point and Qt coupling

[`vita3k/CMakeLists.txt`](https://github.com/ripevil3-commits/Vita3K/blob/649d7d69b2da2eb55f17233376f861a3a32cf12a/vita3k/CMakeLists.txt) includes Qt setup on every non-Android build, adds `gui-qt`, links it into the executable, and generates Qt translation files. The ordinary desktop executable compiles `main.cpp`, `interface.cpp`, and `performance.cpp`.

[`vita3k/main.cpp`](https://github.com/ripevil3-commits/Vita3K/blob/649d7d69b2da2eb55f17233376f861a3a32cf12a/vita3k/main.cpp) includes Qt application/dialog/settings types and performs platform assumptions while initializing paths, logs, config, emulator state, libraries, installed apps and user data. Simply omitting the `gui-qt` library will not make this entry point portable.

### Existing SDL game frontend

[`vita3k/sdl-frontend/CMakeLists.txt`](https://github.com/ripevil3-commits/Vita3K/blob/649d7d69b2da2eb55f17233376f861a3a32cf12a/vita3k/sdl-frontend/CMakeLists.txt) builds the shared frontend around `sdl-frontend/session.cpp` and `frame_host.cpp`, linking `SDL3::SDL3`.

[`sdl-frontend/src/session.cpp`](https://github.com/ripevil3-commits/Vita3K/blob/649d7d69b2da2eb55f17233376f861a3a32cf12a/vita3k/sdl-frontend/src/session.cpp) creates a window, initializes SDL video/audio/gamepad/haptic/sensor/camera subsystems, starts an `AppSessionController`, initializes the renderer/runtime, and runs the Vita app session. This is the nearest existing app-running path to reuse after the PS4 platform boundary is implemented.

[`sdl-frontend/src/frame_host.cpp`](https://github.com/ripevil3-commits/Vita3K/blob/649d7d69b2da2eb55f17233376f861a3a32cf12a/vita3k/sdl-frontend/src/frame_host.cpp) asks SDL3 for Vulkan instance extensions and creates a Vulkan surface from an SDL window. The PS4 target needs either an SDL3 PS4 platform backend that implements these operations or a PS4-specific `FrameHost` implementation connected to the console's graphics runtime.

### Core and renderer dependencies

- `vita3k/emuenv` is a static library that links the emulated app, audio, config, controller, I/O, kernel, networking, renderer, package and support systems.
- `vita3k/cpu` links Dynarmic and Capstone; the guest CPU is ARM A32 while the PS4 host is x86-64.
- `vita3k/renderer` currently compiles both OpenGL and Vulkan sources and links SDL3 plus Vita3K graphics/util libraries. For PS4, renderer selection and the surface path must be explicit.
- `external/CMakeLists.txt` checks that declared Git submodules are populated, then builds many vendored dependencies. A cross build must pin and initialize all required submodules and build each dependency for the PS4 ABI.

## Current prototype branch

The initial source-level integration now exists on the separate [Vita3K PS4 prototype branch](https://github.com/ripevil3-commits/Vita3K/tree/ps4-port-prototype-2026-10-21). It adds a guarded `VITA3K_PS4` CMake option, PS4 data paths, a Qt-free entry point, an SDL3 session path without an SDL desktop window, a Vulkan display-surface provider, and guards for unsupported SDL Cubeb/camera paths.

This is still **source-level work only**. No complete Vita3K CMake build has succeeded on PS4, the required SDL3 PS4 build and RADV/VideoOut WSI/runtime libraries are not supplied by this repository, and there is no tested Vita3K PKG. See the branch's [PS4 build notes](https://github.com/ripevil3-commits/Vita3K/blob/ps4-port-prototype-2026-10-21/docs/PS4_BUILD.md).

## Remaining source tasks

The prototype branch already contains the initial guarded CMake option, Qt-free entry point, PS4 data paths, SDL3 session adaptation, and a provider for the Vulkan display surface. The next work is no longer to add those same skeletons again; it is to make them compile and connect them to a real PS4 runtime.

1. Verify the new C++ sources and CMake target against the current Vita3K headers and templates. The branch has not had a complete PS4 cross-build yet, so API or linker errors may remain.
2. Build SDL3 specifically for PS4, with working ScePad/gamepad and audio backends while desktop video/camera/sensor backends remain off. The staging SDL2 menu is not SDL3 and cannot be substituted directly.
3. Connect a complete PS4 RADV/VideoOut WSI. The surface provider expects `VK_KHR_display` and `VK_KHR_surface`; the WSI must also provide the swapchain, queue submit/flip synchronization, and VideoOut presentation hooks.
4. Cross-build Boost.Filesystem, shader tools, FFmpeg, and the remaining dependencies for the same PS4 ABI. The CMake option intentionally stops instead of compiling host-ABI Boost or using desktop SDL3.
5. Produce `eboot.bin` and the PKG using the local OpenOrbis packaging tools, preserving the local SDK/runtime license restrictions.
6. Test on actual hardware with GoldHEN, verify the shell and Vulkan presentation first, then load a legally obtained test title and collect logs.

The standalone SDL2 shell PKG generated in CI validates only the packaging pipeline for a small native app; it does not validate any of the Vita3K-specific steps above.
 
## Expected dependency order

```text
OpenOrbis ABI + C/C++ runtime
        ↓
native PS4 SDL/platform layer + paths/input/logging
        ↓
Vita3K CPU/JIT + minimal core dependencies
        ↓
PS4-compatible renderer + window/surface/flip path
        ↓
Vita3K application initialization
        ↓
package integration and console test
```

The renderer and the SDL3/PS4 WSI path are expected to be a major blocker. The current OpenOrbis CI proves only that this repository can build the standalone smoke and SDL2 shell test applications.
