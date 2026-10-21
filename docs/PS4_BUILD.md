# Experimental Vita3K PS4 build path

This branch contains an experimental PS4 integration layer. It is **not yet a compiled or console-tested emulator port**.

## Current state

- With `VITA3K_PS4=OFF`, the normal Vita3K desktop and Android build paths remain selected.
- With `VITA3K_PS4=ON`, CMake selects the Qt-free entry point and the PS4-specific SDL frontend `FrameHost`.
- The PS4 host requests `VK_KHR_surface` and `VK_EXT_headless_surface`. This matches the headless-surface path in [orbis-ports Mesa/RADV](https://github.com/orbis-ports/mesa-ps4/blob/orbis/src/vulkan/wsi/wsi_common_headless.c), which sends presentation through VideoOut. The actual extension/swapchain/presentation path is still unverified in this Vita3K integration.
- Vulkan-Headers are declarations only. A PS4 eboot also needs a **static Vulkan entry-point loader** and the matching RADV archive, zlib and Orbis system libraries. The build now supports the [orbis-porting-kit `ps4-vkloader`](https://github.com/orbis-ports/orbis-porting-kit/tree/v1/vkloader) integration, or an explicitly supplied compatible static loader and matching headers. These must all use the same PS4 ABI and Vulkan header revision.
- The entry point can read one installed title ID from `/data/Vita3K/config/launch_app.txt`. A native title browser, Vita package installer UI and console-ready setup flow have not been implemented.
- Audio initially uses Vita3K's SDL3 adapter. Cubeb and SDL camera capture are excluded because no PS4 backend is wired here.

## Major blockers

### SDL3 PS4 backend

The bundled upstream SDL3 source includes a note that its PS4 port is maintained separately and is available to developers under Sony's PlayStation-development NDA; it is not present in this public source tree ([SDL3 PS4 note](https://github.com/libsdl-org/SDL/blob/main/docs/README-ps4.md)). `external/CMakeLists.txt` therefore requires a prebuilt PS4-ABI `SDL3Config.cmake` package. That package must expose working PS4 audio and gamepad/ScePad support. Desktop video, camera and sensor APIs are not used by this frontend path. Without a compatible SDL3 PS4 backend or a completed alternative native frontend, the whole emulator is not buildable end-to-end through the current public source path.

### PS4 compiler, dependencies and Vulkan loader

Stock OpenOrbis packaging tools alone are **not sufficient** to build Vita3K. You need one consistent PS4 cross-compilation environment:

1. The `ps4-cc` and `ps4-c++` wrappers and a compatible PS4 sysroot/libc++ runtime, as expected by `cmake/ps4-wrapper.cmake`.
2. SDL3 built for the same PS4 ABI and installed with `SDL3Config.cmake`.
3. All Vita3K dependencies built for that ABI, including Boost.Filesystem and the relevant FFmpeg, shader and Vulkan dependencies. Initialize all populated Git submodules before configuring.
4. A matching PS4 RADV/Vulkan runtime. The recommended CMake route takes `VITA3K_PS4_ORBIS_KIT_DIR`, `VITA3K_PS4_MESA_SRC` and `VITA3K_PS4_MESA_BUILD`, compiles the kit's `vkloader/` target, and uses the headers belonging to that Mesa tree. The Mesa tree must provide `include/vulkan/vulkan_core.h` and its build must provide `src/amd/vulkan/libvulkan_radeon.a` plus Mesa's zlib archive. Do not mix headers, archives and toolchains from different builds.
5. OpenOrbis packaging tools and runtime assets staged under `/app0/data`; writable state is expected under `/data/Vita3K`.

The public [orbis-porting-kit](https://github.com/orbis-ports/orbis-porting-kit) and [Mesa/RADV PS4 tree](https://github.com/orbis-ports/mesa-ps4) are useful references, but they are not a drop-in full Vita3K SDK or a prebuilt SDL3 PS4 package. The kit repository was archived in September 2026; pin the exact source/runtime version used by your local build.

## Build and package driver

The current `scripts/build-ps4.sh` expects the toolchain and sysroot layout documented in `cmake/ps4-wrapper.cmake`, plus a matching loader configuration. Set real local paths before running:

```sh
export OO_PS4_TOOLCHAIN=/path/to/OpenOrbis-PS4-Toolchain
export PS4_TOOLCHAIN_BIN="$HOME/xemups4/toolchain/bin"
export PS4_SYSROOT="$HOME/xemups4-build/sysroot"

# Prefer the CMake-built ps4-vkloader target from the matching Mesa build.
export VITA3K_PS4_ORBIS_KIT_DIR=/path/to/orbis-porting-kit
export VITA3K_PS4_MESA_SRC=/path/to/matching/mesa-ps4
export VITA3K_PS4_MESA_BUILD=/path/to/matching/mesa-ps4/build-orbis

# Additional platform libraries needed by the Vita3K target, excluding dependencies
# already linked by ps4-vkloader (such as RADV, zlib, SceGnmDriver and SceVideoOut).
export VITA3K_PS4_RUNTIME_INCLUDE_DIRS=/absolute/path/to/extra/runtime/include
export VITA3K_PS4_RUNTIME_LIBRARIES="semicolon;separated;additional;Orbis;libraries"

bash scripts/build-ps4.sh
```

Alternatively, if a matching loader library was built separately, set `VITA3K_PS4_VULKAN_LOADER_LIBRARIES` and `VITA3K_PS4_VULKAN_HEADERS_DIR` to the loader library list and its exact matching headers. Do not mix that option with the `ps4-vkloader` kit route.

The script configures CMake, compiles target `vita3k`, converts the executable to `eboot.bin`, stages assets, and attempts to create `out/Vita3K-PS4-Prototype-v00.01.pkg`. These environment values are examples, not a known working configuration. A produced PKG is not proof that the emulator can boot or render frames.

## Configure example

```sh
cmake -S . -B build-ps4 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/ps4-wrapper.cmake \
  -DVITA3K_PS4=ON \
  -DUSE_DISCORD_RICH_PRESENCE=OFF \
  -DUSE_LTO=NEVER \
  -DBoost_ROOT="$PS4_SYSROOT" \
  -DCMAKE_PREFIX_PATH="$PS4_SYSROOT" \
  -DVITA3K_PS4_ORBIS_KIT_DIR="$VITA3K_PS4_ORBIS_KIT_DIR" \
  -DVITA3K_PS4_MESA_SRC="$VITA3K_PS4_MESA_SRC" \
  -DVITA3K_PS4_MESA_BUILD="$VITA3K_PS4_MESA_BUILD" \
  -DVITA3K_PS4_RUNTIME_INCLUDE_DIRS="$VITA3K_PS4_RUNTIME_INCLUDE_DIRS" \
  -DVITA3K_PS4_RUNTIME_LIBRARIES="$VITA3K_PS4_RUNTIME_LIBRARIES"
```

This is a configuration template, not a verified successful build command. CMake is expected to reject missing headers, loader archives or libraries rather than silently compiling a target that cannot resolve Vulkan entry points.

## Known blockers, in order

1. Obtain a usable PS4-ABI SDL3 backend (or complete a native replacement for the SDL3 audio/input path).
2. Prepare and pin one compatible compiler/sysroot, all PS4-built dependencies, SDL3 and the Mesa/RADV loader archives.
3. Configure CMake with those exact inputs and resolve real cross-compiler and C++23 errors.
4. Confirm the runtime exposes `VK_EXT_headless_surface`, creates a surface and swapchain, and submits frames through VideoOut.
5. Verify ScePad controller input and SDL audio on hardware.
6. Create a PKG from a successful build, install it on a compatible test console, collect logs, and only then begin testing an owned homebrew Vita title.

Until those checks are complete, this remains an integration prototype—not a working Vita3K PS4 beta.
