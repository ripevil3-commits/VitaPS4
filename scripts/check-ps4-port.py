#!/usr/bin/env python3
"""Static integration checks for Vita3K's experimental PS4 path.

These checks catch source-wiring regressions. They do not replace a PS4 cross-build
or on-console presentation test.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise RuntimeError(f"Required integration file is missing: {relative}")
    return path.read_text(encoding="utf-8")


errors: list[str] = []
passed: list[str] = []


def require(label: str, condition: bool, detail: str) -> None:
    if condition:
        passed.append(label)
    else:
        errors.append(f"{label}: {detail}")


cmake = read("vita3k/CMakeLists.txt")
external_cmake = read("external/CMakeLists.txt")
host = read("vita3k/sdl-frontend/src/frame_host_ps4.cpp")
frontend_cmake = read("vita3k/sdl-frontend/CMakeLists.txt")
ps4_input = read("vita3k/sdl-frontend/src/ps4_input.cpp")
main = read("vita3k/ps4/main_ps4.cpp")
session = read("vita3k/sdl-frontend/src/session.cpp")
build = read("scripts/build-ps4.sh")
docs = read("docs/PS4_BUILD.md")

require(
    "PS4 target uses native entry point",
    "elseif(VITA3K_PS4)" in cmake and "ps4/main_ps4.cpp" in cmake,
    "vita3k/CMakeLists.txt must route VITA3K_PS4 to ps4/main_ps4.cpp",
)
require(
    "PS4 frontend selects its platform FrameHost",
    "set(SDL_FRONTEND_FRAME_HOST_SOURCE src/frame_host_ps4.cpp)" in frontend_cmake,
    "the PS4 branch must compile frame_host_ps4.cpp",
)
require(
    "FrameHost asks for the headless-surface extension",
    "VK_EXT_HEADLESS_SURFACE_EXTENSION_NAME" in host
    and "VK_KHR_SURFACE_EXTENSION_NAME" in host
    and "vkCreateHeadlessSurfaceEXT" in host
    and "VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT" in host,
    "FrameHost must create a VK_EXT_headless_surface surface via vkCreateHeadlessSurfaceEXT",
)
require(
    "Old display-plane WSI is not used by FrameHost",
    "VK_KHR_DISPLAY_EXTENSION_NAME" not in host
    and "vkGetPhysicalDeviceDisplayPropertiesKHR" not in host
    and "vkCreateDisplayPlaneSurfaceKHR" not in host,
    "remove the VK_KHR_display display-plane path; PS4 RADV uses headless-surface WSI",
)
require(
    "Build links the actual PS4 runtime libraries",
    "VITA3K_PS4_RUNTIME_LIBRARIES" in cmake
    and "target_link_libraries(vita3k PRIVATE ${VITA3K_PS4_RUNTIME_LIBRARIES})" in cmake,
    "the PS4 target must link the selected PS4 runtime libraries",
)
require(
    "No competing ICD-loader wrapper or custom WSI source is required",
    "VITA3K_PS4_WSI_SOURCE" not in cmake
    and "--wrap=vk_icdGetInstanceProcAddr" not in cmake,
    "remove the obsolete custom WSI source and loader wrapper",
)
require(
    "PS4 requires a real static Vulkan loader",
    "VITA3K_PS4_ORBIS_KIT_DIR" in external_cmake
    and "VITA3K_PS4_MESA_SRC" in external_cmake
    and "VITA3K_PS4_MESA_BUILD" in external_cmake
    and "target_link_libraries(vulkan INTERFACE ps4-vkloader)" in external_cmake
    and "cannot use Vulkan-Headers alone" in external_cmake,
    "external/CMakeLists.txt must wire a real loader and reject a headers-only PS4 Vulkan target",
)
require(
    "PS4 can build bundled headless SDL3 when a target package is unavailable",
    "VITA3K_PS4_USE_BUNDLED_SDL3_FALLBACK" in external_cmake
    and "set(SDL_VIDEO OFF" in external_cmake
    and "set(SDL_DUMMYAUDIO ON" in external_cmake
    and "set(SDL_VIRTUAL_JOYSTICK ON" in external_cmake
    and "add_subdirectory(sdl EXCLUDE_FROM_ALL)" in external_cmake,
    "fallback must disable desktop video, enable silent audio and virtual joystick support",
)
require(
    "Native ScePad input is translated to SDL3",
    "sceUserServiceGetInitialUser" in ps4_input
    and "scePadOpen" in ps4_input
    and "scePadReadState" in ps4_input
    and "SDL_AttachVirtualJoystick" in ps4_input
    and "SDL_SetJoystickVirtualButton" in ps4_input
    and "SDL_SetJoystickVirtualAxis" in ps4_input,
    "native bridge must read ScePad and publish SDL virtual gamepad controls",
)
require(
    "Native input is part of the PS4 frontend target",
    "src/ps4_input.cpp" in frontend_cmake
    and "VITA3K_PS4_PAD_LIBRARIES" in frontend_cmake,
    "build the PS4 bridge and link ScePad/UserService libraries",
)
require(
    "Native input is polled and cleaned up in the PS4 session",
    "ps4_input::initialize()" in session
    and "ps4_input::poll()" in session
    and "ps4_input::shutdown()" in session,
    "wire initialization, per-frame polling, and cleanup into the session",
)
require(
    "RADV headers take precedence and match the linked archive",
    'target_include_directories(vulkan BEFORE INTERFACE "${VITA3K_PS4_MESA_SRC}/include")' in external_cmake
    and "libvulkan_radeon.a" in external_cmake,
    "ensure the exact Mesa headers precede the generic bundled Vulkan-Headers",
)
require(
    "Package driver checks real build prerequisites",
    '[[ -x "$PS4_TOOLCHAIN_BIN/ps4-cc" ]]' in build
    and '[[ -x "$PS4_TOOLCHAIN_BIN/ps4-c++" ]]' in build
    and "VITA3K_PS4_RUNTIME_LIBRARIES" in build
    and "VITA3K_PS4_ORBIS_KIT_DIR" in build
    and "VITA3K_PS4_MESA_SRC" in build
    and "VITA3K_PS4_MESA_BUILD" in build
    and "VITA3K_PS4_VULKAN_LOADER_LIBRARIES" in build
    and "cmake --build" in build
    and "create-fself" in build
    and "PkgTool.Core" in build,
    "build driver must check toolchain/runtime paths and run compile/package stages",
)
require(
    "Package driver does not require unrelated Piglet modules",
    "samples/piglet" not in build and "VITA3K_PS4_WSI_SOURCE" not in build,
    "remove obsolete Piglet/standalone display-WSI package dependencies",
)
require(
    "PS4 session avoids SDL desktop-video initialization",
    "SDL_Init(SDL_INIT_AUDIO | SDL_INIT_GAMEPAD)" in session,
    "PS4 session must initialize supported audio/gamepad facilities without SDL video",
)
require(
    "Entry point has an explicit no-title diagnostic",
    "launch_app.txt" in main and "No title selected" in main,
    "missing-title behavior should be explicit until the title browser is implemented",
)
require(
    "Build documentation reflects the headless-surface and loader requirements",
    "VK_EXT_headless_surface" in docs
    and "ps4-vkloader" in docs
    and "VITA3K_PS4_WSI_SOURCE" not in docs,
    "document the headless surface and a real static loader",
)
require(
    "Build documentation describes silent SDL3 fallback and native input",
    "silent audio" in docs
    and "ScePad" in docs
    and "Known blockers" in docs,
    "document the headless SDL3 fallback, native input, and remaining platform blockers",
)

for item in passed:
    print(f"[PASS] {item}")
for item in errors:
    print(f"[FAIL] {item}", file=sys.stderr)

print(f"PS4 source-contract checks: {len(passed)} passed, {len(errors)} failed")
sys.exit(1 if errors else 0)
