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

## First source changes to make in Vita3K

These are the planned changes for a separate feature branch; they have **not** yet been applied to the Vita3K repository.

1. Add a `VITA3K_PS4` CMake option, default OFF. Reject invalid combinations such as Android + PS4, and leave existing desktop/Android targets unchanged.
2. When that option is ON, do not include Qt setup, create `gui-qt`, link it, or generate Qt translation targets. Add a dedicated `vita3k/ps4/main_ps4.cpp` entry point instead of compiling the desktop `main.cpp`.
3. Force Discord Rich Presence OFF in the PS4 configuration and begin with LTO disabled until the toolchain and link path are stable.
4. Keep the emulator core libraries as normal CMake targets where possible. Gate platform-specific code in dependencies explicitly instead of globally redefining unrelated platform macros.
5. Add a PS4-specific frontend/surface adapter. Do not link the SDL2 prototype from this repository into Vita3K as though it were SDL3-compatible.
6. Select one renderer path. If Vulkan is selected, implement and test the PS4 WSI/surface submission path against the Mesa/RADV runtime before connecting the emulated app launch path.
7. Use the existing `EmuEnvState`, config/path initialization, `app::init`, `init_libraries`, `app::init_apps_list`, and `app::AppSessionController` flow as the reference when writing the PS4 entry point; omit host-OS dialog/window assumptions and define PS4 writable data paths explicitly.

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
