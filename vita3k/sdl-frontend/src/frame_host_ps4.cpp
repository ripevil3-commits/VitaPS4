// Vita3K PS4 display host using the RADV headless-surface WSI.
// Copyright (C) 2026 Vita3K team
// SPDX-License-Identifier: GPL-2.0-or-later

#include "frame_host.h"

#include <cstdio>
#include <string>
#include <vector>

namespace sdl_frontend {

FrameHost::FrameHost() = default;

renderer::DisplayHandle FrameHost::handle() const {
    return std::monostate{};
}

const renderer::VulkanSurfaceProvider *FrameHost::vulkan_surface_provider() const {
    return this;
}

std::vector<const char *> FrameHost::instance_extensions() const {
    // The PS4 RADV/VideoOut WSI is exposed through VK_EXT_headless_surface.
    // It is not a desktop window; presentation is implemented by the PS4 RADV runtime.
    return {
        VK_KHR_SURFACE_EXTENSION_NAME,
        VK_EXT_HEADLESS_SURFACE_EXTENSION_NAME,
    };
}

VkSurfaceKHR FrameHost::create_surface(VkInstance instance) const {
    if (instance == VK_NULL_HANDLE) {
        std::fprintf(stderr, "[Vita3K-PS4] cannot create a surface from a null VkInstance\n");
        return VK_NULL_HANDLE;
    }

    const auto create_headless_surface =
        reinterpret_cast<PFN_vkCreateHeadlessSurfaceEXT>(
            vkGetInstanceProcAddr(instance, "vkCreateHeadlessSurfaceEXT"));
    if (!create_headless_surface) {
        std::fprintf(stderr,
            "[Vita3K-PS4] vkCreateHeadlessSurfaceEXT is unavailable. "
            "Use a PS4 RADV runtime that exposes VK_EXT_headless_surface and VideoOut presentation.\n");
        return VK_NULL_HANDLE;
    }

    VkHeadlessSurfaceCreateInfoEXT create_info{};
    create_info.sType = VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT;

    VkSurfaceKHR surface = VK_NULL_HANDLE;
    const VkResult result =
        create_headless_surface(instance, &create_info, nullptr, &surface);
    if (result != VK_SUCCESS || surface == VK_NULL_HANDLE) {
        std::fprintf(stderr,
            "[Vita3K-PS4] vkCreateHeadlessSurfaceEXT failed (VkResult %d)\n",
            static_cast<int>(result));
        return VK_NULL_HANDLE;
    }

    std::fprintf(stderr,
        "[Vita3K-PS4] created VK_EXT_headless_surface; frame presentation is delegated to RADV/VideoOut\n");
    return surface;
}

void FrameHost::destroy_surface(VkInstance instance, VkSurfaceKHR surface) const {
    if (instance == VK_NULL_HANDLE || surface == VK_NULL_HANDLE)
        return;

    const auto destroy =
        reinterpret_cast<PFN_vkDestroySurfaceKHR>(
            vkGetInstanceProcAddr(instance, "vkDestroySurfaceKHR"));
    if (destroy)
        destroy(instance, surface, nullptr);
}

int FrameHost::drawable_width() const {
    return width;
}

int FrameHost::drawable_height() const {
    return height;
}

std::vector<std::string> FrameHost::font_dirs() const {
    return {"/app0/data/fonts", "/system/fonts"};
}

void *FrameHost::get_proc_address(const char *) const {
    return nullptr;
}

bool FrameHost::make_current() {
    return false;
}

void FrameHost::done_current() {
}

void FrameHost::swap_buffers() {
    // Vulkan frames are presented by the PS4 RADV/VideoOut swapchain.
}

bool FrameHost::set_vsync(bool) {
    return true;
}

void FrameHost::prepare_for_render_thread() {
}

void FrameHost::destroy_render_context() {
}

} // namespace sdl_frontend
