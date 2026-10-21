# Reference-port notes for VitaPS4

**Updated:** 2026-10-21  
**Purpose:** identify the engineering patterns that can be adapted from public PS4 emulator ports without pretending their code can be transplanted directly.

## PS4SX2: packaging and PS4 runtime integration

Repository: https://github.com/iHaiDeeZ/PS4SX2

Files inspected:
- [PS4 build driver](https://github.com/iHaiDeeZ/PS4SX2/blob/main/ps4/build-ps4.sh)
- [PS4 Makefile](https://github.com/iHaiDeeZ/PS4SX2/blob/main/ps4/Makefile.ps4)
- [PS4 link target](https://github.com/iHaiDeeZ/PS4SX2/blob/main/ps4/link/CMakeLists.txt)
- [PKG helper](https://github.com/iHaiDeeZ/PS4SX2/blob/main/ps4/make-pkg.sh)

Confirmed implementation patterns:

1. **Separate console build path.** The project has a dedicated `ps4/` target rather than treating the desktop CMake target as a PS4 executable.
2. **Explicit PS4 ABI and CRT.** Its build uses the `x86_64-pc-freebsd12-elf` target and a toolchain sysroot/link script/CRT. Its runtime depends on more than the presence of a generic CMake compiler.
3. **Manual source and dependency selection.** The PS4 Makefile enumerates sources and omits or replaces incompatible desktop pieces. The linking target adds PS4-specific compatibility and Vulkan window-system code.
4. **A distinct package stage.** The helper builds `param.sfo`, assembles a GP4 project, and invokes `PkgTool.Core pkg_build`. Runtime modules and data are staged deliberately.
5. **Graphics is a platform port.** The link setup wires the renderer to a PS4-adapted Mesa/RADV path. This is not equivalent to installing the ordinary desktop Vulkan loader.

**What VitaPS4 should reuse:** the separation of build, link, stage, and package steps; repeatable environment checks; and a small source list for the first native app shell.

**What VitaPS4 should not copy:** the PCSX2 source list, its PS2 GS renderer, its CPU tuning flags, or PS5SX2/CEMUPS4-specific compatibility code. Those are tied to a different emulator and runtime.

## M33: dependencies and frontend isolation

Repository: https://github.com/iHaiDeeZ/M33

Files inspected:
- [PS4 environment setup](https://github.com/iHaiDeeZ/M33/blob/main/scripts/ps4-env.sh)
- [PPSSPP configuration](https://github.com/iHaiDeeZ/M33/blob/main/scripts/configure-ppsspp.sh)
- [PPSSPP build script](https://github.com/iHaiDeeZ/M33/blob/main/scripts/build-ppsspp.sh)
- [PS4 port layer](https://github.com/iHaiDeeZ/M33/tree/main/port)

M33 does not merely run upstream PPSSPP unchanged. Its configuration points at a PS4-specific toolchain file, sysroot and Mesa build; disables optional subsystems that are unsuitable for the target; and provides a PS4 frontend and platform/runtime source files. Its environment helper also avoids leaking make-oriented compiler flags into CMake configuration.

**What VitaPS4 should reuse:** explicit dependency toggles, a PS4-only frontend boundary, a known sysroot, and a reproducible configure/build sequence.

**What VitaPS4 should not assume:** that PPSSPP's PS4 frontend or PSP JIT can serve as Vita3K's frontend or ARMv7 emulation. The guest CPU, GPU translation requirements, API surface and dependencies differ.

## A Vita3K-specific risk list

The separate Vita3K source tree currently sets C++23, uses Dynarmic's A32 frontend, builds a Qt desktop frontend on non-Android platforms, and contains both OpenGL and Vulkan renderer paths. That creates four early questions:

- **Compiler/runtime:** can the chosen PS4 C++ toolchain compile the language/library features Vita3K actually uses?
- **JIT:** can Dynarmic's x86-64 host backend and generated-code memory assumptions work under the target PS4 process/runtime?
- **Frontend:** what minimal replacement can render a menu, read controller input, exit cleanly, and access writable data?
- **GPU:** which renderer can be made to work with the chosen PS4 graphics runtime? A desktop Vulkan build succeeding is not evidence that PS4 GPU submission works.

Vita3K's current fork is linked from the main README, but this VitaPS4 repository is still a bootstrap repository; the emulator source has not yet been integrated into this tree.

## Proposed order of work

1. Build and launch the tiny native smoke app first. This isolates the toolchain and package pipeline from emulator problems.
2. Add a PS4 application shell and test controller input and writable storage without loading Vita3K.
3. Create a separate Vita3K PS4 build target and disable desktop-only features deliberately.
4. Cross-build only the minimal dependency set, starting with the CPU/JIT and logging/filesystem pieces.
5. Bring up one renderer path and collect console logs before integrating the full core.
6. Integrate the emulator core, then test with legally obtained user data on real hardware.

## Licensing note

Use these projects as engineering references first. PS4SX2 and M33 have different upstream projects and license obligations; do not copy code across repositories without checking its source license and preserving required notices. This note does not grant permission to redistribute proprietary runtime modules, firmware, keys, or game content.
