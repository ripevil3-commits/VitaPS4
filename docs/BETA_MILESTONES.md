# Vita3K PS4 — earliest beta milestone

This tracks the smallest honest beta target. A source import or passing script check is not a runnable beta.

## Beta 0: first bootable homebrew shell
- [x] Import the Vita3K source tree into this branch.
- [x] Add a PS4 entry point and an experimental build/package driver.
- [x] Implement the source-side Vulkan FrameHost using `VK_EXT_headless_surface`.
- [x] Add a static Vulkan loader path with matching Mesa header/archive checks.
- [x] Add a source-side ScePad-to-SDL3 virtual gamepad bridge.
- [x] Add bundled SDL3 headless fallback with virtual joystick support and silent audio.
- [ ] Prepare a reproducible PS4 compiler/sysroot and build dependencies for the PS4 ABI.
- [ ] Configure and compile the complete Vita3K target, then resolve real toolchain/link failures.
- [ ] Verify on a real PS4 that RADV exposes the required extension and presents frames through VideoOut.
- [ ] Replace dummy audio with a working PS4 output backend.
- [ ] Produce a PKG from a successful build and verify its metadata/assets.
- [ ] Launch it on a compatible homebrew setup and capture logs/screenshots.

## Beta 1: attempt one installed Vita title
- [ ] Add a usable title-selection/install flow; the current entry point only reads an installed title ID from `/data/Vita3K/config/launch_app.txt`.
- [ ] Verify controller input and app initialization on hardware.
- [ ] Test an owned homebrew Vita title and record the result.

## Current evidence and limits

The import branch contains the implementation work above. On 2026-10-21, GitHub Actions passed the source-contract checks, compiled the PS4 FrameHost against Vulkan headers, compiled the ScePad-to-SDL3 bridge against public SDK headers, and parsed the build scripts. These are useful source-level checks, not an end-to-end PS4 cross-build: the complete Vita3K target has not been compiled with a prepared PS4 sysroot, and no PKG has been verified on a console. A beta label is held until a real binary is built and launched.

## Next critical path

1. Pass the native-input syntax check.
2. Configure the entire project against one prepared PS4 sysroot and matching Vulkan loader/dependencies.
3. Fix actual compile/link failures and verify one Vulkan present on hardware.
4. Package and test the first bootable shell before investing in game compatibility.
