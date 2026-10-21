# Experimental Vita3K PS4 build path

This branch contains an experimental PS4 integration layer. It is **not yet a compiled or console-tested emulator port**.

## Current state

- With `VITA3K_PS4=OFF`, the normal Vita3K desktop and Android build paths remain selected.
- With `VITA3K_PS4=ON`, CMake selects the Qt-free entry point and the PS4-specific SDL frontend `FrameHost`.
- The PS4 host requests `VK_KHR_surface` and `VK_EXT_headless_surface`. This matches the headless-surface path used by the current [orbis-ports Mesa/RADV PS4 WSI](https://github.com/orbis-ports/mesa-ps4/blob/orbis/src/vulkan/wsi/wsi_common_headless.c), which routes presentation through VideoOut. It must be supplied by a compatible PS4 RADV runtime; this repository does not build Mesa for you.
- The entry point can read one installed title ID from `/data/Vita3K/config/launch_app.txt`. A native title browser, Vita package installer UI, and console-ready setup flow have not been implemented.
- Audio initially uses Vita3K's SDL3 adapter. Cubeb and SDL camera capture are excluded because no PS4 backends are wired here.

## Required build environment

Stock OpenOrbis packaging tools alone are **not sufficient** to build Vita3K. You need a prepared PS4 cross-compilation environment:

1. The `ps4-cc` and `ps4-c++` wrappers and a compatible PS4 sysroot/libc++ runtime. The supplied `cmake/ps4-wrapper.cmake` documents the expected layout.
2. SDL3 built for the PS4 ABI and installed with an `SDL3Config.cmake` package. It must provide working ScePad/gamepad events and audio output; desktop video, camera, and sensor APIs are not used by this frontend path.
3. Vita3K dependencies built for that same ABI, including Boost.Filesystem and the relevant FFmpeg, shader, and Vulkan dependencies. Initialize all populated Git submodules before configuring.
4. A matching PS4 RADV/Vulkan runtime exposing `VK_EXT_headless_surface` and PS4 VideoOut presentation, plus its required Orbis libraries. Provide the library names/paths through `VITA3K_PS4_RUNTIME_LIBRARIES` and optional include paths through `VITA3K_PS4_RUNTIME_INCLUDE_DIRS`. A second custom `VK_KHR_display` WSI source is **not required** and must not wrap `vk_icdGetInstanceProcAddr` for this path.
5. The OpenOrbis packaging tools, and runtime assets staged under `/app0/data`; writable state is expected under `/data/Vita3K`.

Useful references include [orbis-ports Mesa/RADV](https://github.com/orbis-ports/mesa-ps4), [orbis-compat](https://github.com/orbis-ports/orbis-compat), and [PS4SX2](https://github.com/iHaiDeeZ/PS4SX2). PS4SX2's custom `VK_KHR_display` layer is a different approach, not a source file to drop into this headless-surface integration.

## Build and package driver

After preparing the cross-compiled dependencies and matching runtime, set the real local paths and run:

```sh
export OO_PS4_TOOLCHAIN=/path/to/OpenOrbis-PS4-Toolchain
export PS4_TOOLCHAIN_BIN="$HOME/xemups4/toolchain/bin"
export PS4_SYSROOT="$HOME/xemups4-build/sysroot"
export VITA3K_PS4_RUNTIME_INCLUDE_DIRS=/absolute/path/to/ps4-runtime/include
export VITA3K_PS4_RUNTIME_LIBRARIES="semicolon;separated;PS4;runtime;library;names"

bash scripts/build-ps4.sh
```

The script configures CMake, compiles target `vita3k`, converts the executable to `eboot.bin`, stages the assets, and attempts to create `out/Vita3K-PS4-Prototype-v00.01.pkg`. The sample values above are placeholders, not a known working environment. A produced PKG is not proof that the emulator can boot or present frames.

## Configure example

```sh
export PS4_TOOLCHAIN_BIN="$HOME/xemups4/toolchain/bin"
export PS4_SYSROOT="$HOME/xemups4-build/sysroot"

cmake -S . -B build-ps4 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/ps4-wrapper.cmake \
  -DVITA3K_PS4=ON \
  -DUSE_DISCORD_RICH_PRESENCE=OFF \
  -DUSE_LTO=NEVER \
  -DBoost_ROOT="$PS4_SYSROOT" \
  -DCMAKE_PREFIX_PATH="$PS4_SYSROOT" \
  -DVITA3K_PS4_RUNTIME_INCLUDE_DIRS="/absolute/path/to/ps4-runtime/include" \
  -DVITA3K_PS4_RUNTIME_LIBRARIES="absolute-paths-or-CMake-library-targets"
```

This is a configuration template, not a verified successful build command. Supply libraries matching the local PS4 runtime and sysroot.

## Known blockers, in order

1. Configure CMake with the real PS4 sysroot, SDL3 package and built dependencies; resolve actual cross-compiler/C++23 failures.
2. Confirm the chosen RADV runtime reports `VK_EXT_headless_surface`, creates the surface, supports the needed swapchain, and successfully submits/presents frames through VideoOut.
3. Compile and link the full Vita3K core. Dynarmic/JIT host-code generation and executable-memory behavior must be verified on the PS4 ABI.
4. Verify ScePad controller input and SDL audio on hardware.
5. Create a PKG from a successful build, install it on a compatible test console, capture logs, and only then begin title-compatibility testing with an owned homebrew title.

Until those checks are complete, this remains an integration prototype—not a working Vita3K PS4 beta.
