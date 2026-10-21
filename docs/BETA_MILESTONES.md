# Vita3K PS4 — earliest beta milestone

This document tracks the smallest honest beta target. A GitHub source import or a successful shell-script check is not a runnable beta.

## Beta 0: bootable homebrew shell
- [x] Import the Vita3K source tree into this branch.
- [x] Add a PS4 entry point and experimental build/package driver.
- [ ] Prepare a reproducible PS4 compiler/sysroot and PS4-built dependency set.
- [ ] Integrate and link a working RADV/VideoOut Vulkan WSI; verify surface creation, swapchain creation, and frame presentation.
- [ ] Build the Vita3K target and resolve actual PS4 compiler/linker errors.
- [ ] Produce a PKG from the successful build and verify package metadata/assets.
- [ ] Launch on a compatible PS4 homebrew setup and capture logs/screenshots.

## Beta 1: attempt one installed Vita title
- [ ] Add a usable title-selection/install flow; the current entry point only reads an installed title ID from `/data/Vita3K/config/launch_app.txt`.
- [ ] Verify app initialization and controller input on hardware.
- [ ] Test at least one legally obtained homebrew Vita title and record the result.

## Current blockers
The PS4 build has not been validated end-to-end. The build script deliberately requires a local PS4 sysroot, PS4 compiler wrappers, a compatible Vulkan WSI source/runtime libraries, and OpenOrbis packaging tools. These are environment-specific and are not supplied by the source import itself. Do not label any generated artifact as a beta until the build and device launch are verified.

## Fastest route
1. Secure a reproducible PS4 build environment and confirm the expected compiler/SDK paths.
2. Make CMake configure and compile the smallest PS4 target, then fix failures in order.
3. Finish Vulkan WSI and present one frame before attempting game compatibility.
4. Package and test the first bootable build; then expand to title launching.
