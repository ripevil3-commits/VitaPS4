# Experimental Vita3K PS4 build path

This branch contains an experimental PS4 integration layer. It is **not yet a compiled or console-tested emulator port**.

## Current state

- With `VITA3K_PS4=OFF`, the normal Vita3K desktop and Android build paths remain selected.
- With `VITA3K_PS4=ON`, CMake selects the Qt-free entry point and PS4-specific `FrameHost`.
- The PS4 host requests `VK_KHR_surface` and `VK_EXT_headless_surface`. This matches the headless-surface route in [orbis-ports Mesa/RADV](https://github.com/orbis-ports/mesa-ps4/blob/orbis/src/vulkan/wsi/wsi_common_headless.c), which routes frames through VideoOut. Surface creation, swapchain setup, and presentation remain unverified in this Vita3K integration.
- The PS4 frontend has a source-side ScePad bridge that reads the logged-in user's DualShock 4 and exposes it through SDL3's virtual-gamepad API. It has syntax CI against public OpenOrbis headers, but input is not yet tested on a console.
- When no target SDL3 package is available, `external/CMakeLists.txt` can build the bundled public SDL3 in headless mode, with no desktop video and **dummy/silent audio**. This is an early bring-up path, not a full audio backend. A compatible PS4 SDL3 package can be provided instead.
- Vulkan-Headers only declares Vulkan APIs. A PS4 eboot also needs a **static Vulkan entry-point loader** plus the matching RADV archive, zlib and Orbis system libraries. The build supports the [orbis-porting-kit `ps4-vkloader`](https://github.com/orbis-ports/orbis-porting-kit/tree/v1/vkloader) route or a separately built, compatible static loader with matching headers. Keep compiler, headers and archives from one matching build.
- The entry point can read one installed title ID from `/data/Vita3K/config/launch_app.txt`. A native title browser and Vita package-installer UI have not been implemented.

## Requirements

Stock OpenOrbis packaging tools alone are **not sufficient** to build Vita3K. The full build still needs all of these items:

1. The `ps4-cc` and `ps4-c++` wrappers and a compatible PS4 sysroot/libc++ runtime, as expected by `cmake/ps4-wrapper.cmake`.
2. All Vita3K dependencies built for that same PS4 ABI, including Boost.Filesystem and the relevant FFmpeg, shader and Vulkan dependencies. Initialize populated Git submodules before configuring.
3. A matching PS4 RADV/Vulkan runtime. The recommended CMake route takes `VITA3K_PS4_ORBIS_KIT_DIR`, `VITA3K_PS4_MESA_SRC` and `VITA3K_PS4_MESA_BUILD`, compiles the kit's `vkloader/` target and uses that Mesa source tree's headers. The Mesa source must provide `include/vulkan/vulkan_core.h`, and its build must provide `src/amd/vulkan/libvulkan_radeon.a` and the expected support archives. Do not mix headers, archives and toolchains.
4. `ScePad` and `SceUserService` libraries to link the native input bridge. `VITA3K_PS4_PAD_LIBRARIES` defaults to `ScePad;SceUserService`.
5. OpenOrbis packaging tools and assets staged under `/app0/data`; writable state is expected under `/data/Vita3K`.

The public [orbis-porting-kit](https://github.com/orbis-ports/orbis-porting-kit) and [Mesa/RADV PS4 tree](https://github.com/orbis-ports/mesa-ps4) are reference components, not a prebuilt complete emulator SDK. Pin a mutually compatible source/runtime revision.

## Build and package driver

From a Linux/WSL environment that has the PS4 toolchain and dependencies installed, set real paths and run:

```sh
export OO_PS4_TOOLCHAIN=/path/to/OpenOrbis-PS4-Toolchain
export PS4_TOOLCHAIN_BIN="$HOME/xemups4/toolchain/bin"
export PS4_SYSROOT="$HOME/xemups4-build/sysroot"

export VITA3K_PS4_ORBIS_KIT_DIR=/path/to/orbis-porting-kit
export VITA3K_PS4_MESA_SRC=/path/to/matching/mesa-ps4
export VITA3K_PS4_MESA_BUILD=/path/to/matching/mesa-ps4/build-orbis

# Additional Orbis/system libraries used by Vita3K, excluding those already linked
# by ps4-vkloader; include other libraries required by the exact local dependency build.
export VITA3K_PS4_RUNTIME_INCLUDE_DIRS=/absolute/path/to/extra/runtime/include
export VITA3K_PS4_RUNTIME_LIBRARIES="semicolon;separated;additional;Orbis;libraries"

bash scripts/build-ps4.sh
```

If you have a separately built static Vulkan loader, use `VITA3K_PS4_VULKAN_LOADER_LIBRARIES` and `VITA3K_PS4_VULKAN_HEADERS_DIR` instead of the three orbis-kit/Mesa variables.

The script configures CMake, compiles target `vita3k`, converts the output to `eboot.bin`, stages assets, and attempts to create `out/Vita3K-PS4-Prototype-v00.01.pkg`. The variable values above are examples, not a known working configuration. A generated PKG is not proof that the emulator boots or presents frames.

## Build switches

- `VITA3K_PS4_USE_BUNDLED_SDL3_FALLBACK=ON` (default): build bundled SDL3 without a video backend, enable virtual joystick support and use dummy audio if a prebuilt PS4 SDL3 package is unavailable.
- `VITA3K_PS4_USE_BUNDLED_SDL3_FALLBACK=OFF`: require a target `SDL3Config.cmake` package.
- `VITA3K_PS4_PAD_LIBRARIES`: defaults to `ScePad;SceUserService`; override if the selected toolchain uses different library names.

## Known blockers, in order

1. Configure the real PS4 sysroot, bundled SDL3 headless fallback, PS4-built dependencies and matching Vulkan loader.
2. Resolve any actual compiler and linker failures from a complete CMake configure/build; current CI checks only source wiring, host syntax and shell syntax—not a PS4 binary.
3. Verify the RADV runtime exposes `VK_EXT_headless_surface`, creates a surface/swapchain and presents at least one frame through VideoOut.
4. Test ScePad input on the logged-in user and replace dummy audio with a real PS4 audio backend.
5. Produce the PKG from a successful build, install it on a compatible test console, collect logs, and only then attempt an owned homebrew Vita title.

Until these checks are complete, this remains an integration prototype—not a working Vita3K PS4 beta.
