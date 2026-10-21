#pragma once

namespace sdl_frontend::ps4_input {

// Initialize the Orbis ScePad bridge and expose the first logged-in controller
// as a normal SDL3 virtual gamepad. Must be called after SDL_Init(SDL_INIT_GAMEPAD).
bool initialize();

// Poll ScePad and update the SDL3 virtual gamepad. Call once per frontend frame.
void poll();

// Safe to call after partial initialization and before SDL_Quit().
void shutdown();

} // namespace sdl_frontend::ps4_input
