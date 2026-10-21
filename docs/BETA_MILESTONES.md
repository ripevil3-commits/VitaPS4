# Vita3K PS4 — earliest beta milestone

This document tracks the smallest honest beta target. A GitHub source import or a successful shell-script check is not a runnable beta.

## Beta 0: bootable homebrew shell
- [x] Import the Vita3K source tree into this branch.
- [x] Add a PS4 entry point and experimental build/package driver.
- [ ] Prepare a reproducible PS4 compiler/sysroot and PS4-built dependency set.
- [ ] Obtain/build a compatible PS4-ABI SDL3 backend (or implement a complete native audio/controller replacement).
- [x] Implement the source-side PS4 FrameHost using `VK_EXT_headless_surface`.
- [x] Add a required static Vulkan loader path and pair Mesa headers with the matching RADV archive.
- [ ] Verify on the actual PS4 RADV runtime that the extension is exposed, the surface/swapchain succeeds, and frames reach VideoOut.
- [ ] Build the Vita3K target and resolve actual PS4 compiler/linker errors.
- [ ] Produce a PKG from the successful build and verify package metadata/assets.
- [ ] Launch on a compatible PS4 homebrew setup and capture logs/screenshots.

## Beta 1: attempt one installed Vita title
- [ ] Add a usable title-selection/install flow; the current entry point only reads an installed title ID from `/data/Vita3K/config/launch_app.txt`.
- [ ] Verify app initialization and controller input on hardware.
- [ ] Test at least one legally obtained homebrew Vita title and record the result.

## Current blockers
The PS4 build has not been validated end-to-end. The build requires a local PS4 sysroot/compiler, PS4-built dependencies, a PS4-ABI SDL3 package, a compatible static Vulkan loader plus matching RADV headers/archive, VideoOut/system libraries, and OpenOrbis packaging tools. The public SDL3 source tree notes that its PS4 backend is maintained separately and is available under Sony's PlayStation-development NDA; this branch does not include that backend. Do not label any generated artifact as a beta until the full build and device launch are verified.

## Fastest route
1. Secure a reproducible PS4 build environment and confirm the expected compiler/SDK paths.
2. Configure CMake using those exact dependencies and resolve the first cross-build failures.
3. Confirm the runtime surface/swapchain and present at least one frame before attempting game compatibility.
4. Package and test the first bootable build; then expand to title launching.
