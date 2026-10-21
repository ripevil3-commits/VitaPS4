// Open-source ScePad -> SDL3 virtual gamepad bridge for the PS4 homebrew path.
// Copyright (C) 2026 Vita3K team
// SPDX-License-Identifier: GPL-2.0-or-later

#include "ps4_input.h"

#ifdef VITA3K_PS4

#include <SDL3/SDL.h>
#include <orbis/Pad.h>
#include <orbis/UserService.h>

#include <array>
#include <cstdint>

namespace sdl_frontend::ps4_input {
namespace {

constexpr uint16_t kSonyVendorId = 0x054c;
constexpr uint16_t kDualShock4ProductId = 0x05c4;

bool active = false;
int32_t pad_handle = -1;
SDL_JoystickID virtual_instance = 0;
SDL_Joystick *virtual_joystick = nullptr;

struct ButtonBinding {
    int sdl_button;
    uint32_t orbis_mask;
};

constexpr std::array<ButtonBinding, 14> kButtons{{
    {SDL_GAMEPAD_BUTTON_SOUTH, ORBIS_PAD_BUTTON_CROSS},
    {SDL_GAMEPAD_BUTTON_EAST, ORBIS_PAD_BUTTON_CIRCLE},
    {SDL_GAMEPAD_BUTTON_WEST, ORBIS_PAD_BUTTON_SQUARE},
    {SDL_GAMEPAD_BUTTON_NORTH, ORBIS_PAD_BUTTON_TRIANGLE},
    {SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, ORBIS_PAD_BUTTON_L1},
    {SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, ORBIS_PAD_BUTTON_R1},
    {SDL_GAMEPAD_BUTTON_LEFT_STICK, ORBIS_PAD_BUTTON_L3},
    {SDL_GAMEPAD_BUTTON_RIGHT_STICK, ORBIS_PAD_BUTTON_R3},
    {SDL_GAMEPAD_BUTTON_START, ORBIS_PAD_BUTTON_OPTIONS},
    {SDL_GAMEPAD_BUTTON_TOUCHPAD, ORBIS_PAD_BUTTON_TOUCH_PAD},
    {SDL_GAMEPAD_BUTTON_DPAD_UP, ORBIS_PAD_BUTTON_UP},
    {SDL_GAMEPAD_BUTTON_DPAD_DOWN, ORBIS_PAD_BUTTON_DOWN},
    {SDL_GAMEPAD_BUTTON_DPAD_LEFT, ORBIS_PAD_BUTTON_LEFT},
    {SDL_GAMEPAD_BUTTON_DPAD_RIGHT, ORBIS_PAD_BUTTON_RIGHT},
}};

bool is_already_initialized(int32_t result) {
    return static_cast<uint32_t>(result) == ORBIS_USER_SERVICE_ERROR_ALREADY_INITIALIZED;
}

void clear_virtual_state() {
    if (!virtual_joystick)
        return;

    for (const auto &binding : kButtons)
        SDL_SetJoystickVirtualButton(virtual_joystick, binding.sdl_button, false);

    for (int axis = 0; axis < SDL_GAMEPAD_AXIS_COUNT; ++axis) {
        const Sint16 value = axis >= SDL_GAMEPAD_AXIS_LEFT_TRIGGER
            ? SDL_JOYSTICK_AXIS_MIN
            : 0;
        SDL_SetJoystickVirtualAxis(virtual_joystick, axis, value);
    }
}

Sint16 stick_axis(uint8_t value) {
    // ScePad reports 0..255 with 128 at rest; map to SDL's signed 16-bit axis.
    return static_cast<Sint16>(static_cast<int>(value) * 257 - 32768);
}

bool open_native_pad() {
    OrbisUserServiceInitializeParams user_params{};
    user_params.priority = ORBIS_KERNEL_PRIO_FIFO_LOWEST;
    const int32_t user_init = sceUserServiceInitialize(&user_params);
    if (user_init < 0 && !is_already_initialized(user_init)) {
        SDL_Log("[Vita3K-PS4] sceUserServiceInitialize failed: 0x%08x",
                static_cast<unsigned>(user_init));
        return false;
    }

    const int32_t pad_init = scePadInit();
    if (pad_init < 0) {
        SDL_Log("[Vita3K-PS4] scePadInit failed: 0x%08x",
                static_cast<unsigned>(pad_init));
        return false;
    }

    int32_t user_id = ORBIS_USER_SERVICE_USER_ID_INVALID;
    const int32_t user_result = sceUserServiceGetInitialUser(&user_id);
    if (user_result < 0 || user_id == ORBIS_USER_SERVICE_USER_ID_INVALID) {
        SDL_Log("[Vita3K-PS4] no logged-in user available for ScePad (result 0x%08x)",
                static_cast<unsigned>(user_result));
        return false;
    }

    pad_handle = scePadOpen(user_id, ORBIS_PAD_PORT_TYPE_STANDARD, 0, nullptr);
    if (static_cast<uint32_t>(pad_handle) == ORBIS_PAD_ERROR_ALREADY_OPENED) {
        pad_handle = scePadGetHandle(user_id, ORBIS_PAD_PORT_TYPE_STANDARD, 0);
    }
    if (pad_handle < 0) {
        SDL_Log("[Vita3K-PS4] scePadOpen failed for user %d: 0x%08x",
                user_id, static_cast<unsigned>(pad_handle));
        pad_handle = -1;
        return false;
    }

    return true;
}

} // namespace

bool initialize() {
    if (active)
        return true;

    if (!open_native_pad()) {
        if (pad_handle >= 0) {
            scePadClose(pad_handle);
            pad_handle = -1;
        }
        return false;
    }

    SDL_VirtualJoystickDesc desc{};
    desc.version = sizeof(desc);
    desc.type = SDL_JOYSTICK_TYPE_GAMEPAD;
    desc.vendor_id = kSonyVendorId;
    desc.product_id = kDualShock4ProductId;
    desc.naxes = SDL_GAMEPAD_AXIS_COUNT;
    desc.nbuttons = SDL_GAMEPAD_BUTTON_COUNT;
    desc.button_mask = SDL_GAMEPAD_BUTTON_COUNT >= 32
        ? 0xffffffffu
        : ((1u << SDL_GAMEPAD_BUTTON_COUNT) - 1u);
    desc.axis_mask = (1u << SDL_GAMEPAD_AXIS_COUNT) - 1u;
    desc.name = "PS4 DualShock 4 (ScePad)";

    virtual_instance = SDL_AttachVirtualJoystick(&desc);
    if (virtual_instance == 0) {
        SDL_Log("[Vita3K-PS4] SDL_AttachVirtualJoystick failed: %s", SDL_GetError());
        scePadClose(pad_handle);
        pad_handle = -1;
        return false;
    }

    virtual_joystick = SDL_OpenJoystick(virtual_instance);
    if (!virtual_joystick) {
        SDL_Log("[Vita3K-PS4] SDL_OpenJoystick failed: %s", SDL_GetError());
        SDL_DetachVirtualJoystick(virtual_instance);
        virtual_instance = 0;
        scePadClose(pad_handle);
        pad_handle = -1;
        return false;
    }

    active = true;
    poll();
    SDL_Log("[Vita3K-PS4] native ScePad input connected through an SDL3 virtual gamepad");
    return true;
}

void poll() {
    if (!active || !virtual_joystick || pad_handle < 0)
        return;

    OrbisPadData data{};
    const int32_t result = scePadReadState(pad_handle, &data);
    if (result < 0 || !data.connected) {
        clear_virtual_state();
        return;
    }

    for (const auto &binding : kButtons) {
        SDL_SetJoystickVirtualButton(
            virtual_joystick,
            binding.sdl_button,
            (data.buttons & binding.orbis_mask) != 0);
    }

    SDL_SetJoystickVirtualAxis(virtual_joystick, SDL_GAMEPAD_AXIS_LEFTX, stick_axis(data.leftStick.x));
    SDL_SetJoystickVirtualAxis(virtual_joystick, SDL_GAMEPAD_AXIS_LEFTY, stick_axis(data.leftStick.y));
    SDL_SetJoystickVirtualAxis(virtual_joystick, SDL_GAMEPAD_AXIS_RIGHTX, stick_axis(data.rightStick.x));
    SDL_SetJoystickVirtualAxis(virtual_joystick, SDL_GAMEPAD_AXIS_RIGHTY, stick_axis(data.rightStick.y));
    SDL_SetJoystickVirtualAxis(virtual_joystick, SDL_GAMEPAD_AXIS_LEFT_TRIGGER, stick_axis(data.analogButtons.l2));
    SDL_SetJoystickVirtualAxis(virtual_joystick, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER, stick_axis(data.analogButtons.r2));
}

void shutdown() {
    if (virtual_joystick) {
        clear_virtual_state();
        SDL_CloseJoystick(virtual_joystick);
        virtual_joystick = nullptr;
    }
    if (virtual_instance != 0) {
        SDL_DetachVirtualJoystick(virtual_instance);
        virtual_instance = 0;
    }
    if (pad_handle >= 0) {
        scePadClose(pad_handle);
        pad_handle = -1;
    }
    active = false;
}

} // namespace sdl_frontend::ps4_input

#endif // VITA3K_PS4
