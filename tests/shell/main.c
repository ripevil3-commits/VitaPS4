#include <SDL2/SDL.h>

#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#define WINDOW_WIDTH 1280
#define WINDOW_HEIGHT 720
#define MENU_ITEMS 3

/* PS4 button numbers follow the mapping used by the M33 SDL2 frontend. */
enum {
    PAD_CROSS = 0,
    PAD_OPTIONS = 9,
    PAD_UP = 13,
    PAD_DOWN = 14
};

static const char FONT_CHARS[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:-./?";
static const unsigned char FONT_GLYPHS[][5] = {
    {0x7E,0x11,0x11,0x11,0x7E}, /* A */
    {0x7F,0x49,0x49,0x49,0x36}, /* B */
    {0x3E,0x41,0x41,0x41,0x22}, /* C */
    {0x7F,0x41,0x41,0x22,0x1C}, /* D */
    {0x7F,0x49,0x49,0x49,0x41}, /* E */
    {0x7F,0x09,0x09,0x09,0x01}, /* F */
    {0x3E,0x41,0x49,0x49,0x7A}, /* G */
    {0x7F,0x08,0x08,0x08,0x7F}, /* H */
    {0x00,0x41,0x7F,0x41,0x00}, /* I */
    {0x20,0x40,0x41,0x3F,0x01}, /* J */
    {0x7F,0x08,0x14,0x22,0x41}, /* K */
    {0x7F,0x40,0x40,0x40,0x40}, /* L */
    {0x7F,0x02,0x0C,0x02,0x7F}, /* M */
    {0x7F,0x04,0x08,0x10,0x7F}, /* N */
    {0x3E,0x41,0x41,0x41,0x3E}, /* O */
    {0x7F,0x09,0x09,0x09,0x06}, /* P */
    {0x3E,0x41,0x51,0x21,0x5E}, /* Q */
    {0x7F,0x09,0x19,0x29,0x46}, /* R */
    {0x46,0x49,0x49,0x49,0x31}, /* S */
    {0x01,0x01,0x7F,0x01,0x01}, /* T */
    {0x3F,0x40,0x40,0x40,0x3F}, /* U */
    {0x1F,0x20,0x40,0x20,0x1F}, /* V */
    {0x7F,0x20,0x18,0x20,0x7F}, /* W */
    {0x63,0x14,0x08,0x14,0x63}, /* X */
    {0x07,0x08,0x70,0x08,0x07}, /* Y */
    {0x61,0x51,0x49,0x45,0x43}, /* Z */
    {0x3E,0x51,0x49,0x45,0x3E}, /* 0 */
    {0x00,0x42,0x7F,0x40,0x00}, /* 1 */
    {0x62,0x51,0x49,0x49,0x46}, /* 2 */
    {0x22,0x41,0x49,0x49,0x36}, /* 3 */
    {0x18,0x14,0x12,0x7F,0x10}, /* 4 */
    {0x2F,0x49,0x49,0x49,0x31}, /* 5 */
    {0x3E,0x49,0x49,0x49,0x32}, /* 6 */
    {0x01,0x71,0x09,0x05,0x03}, /* 7 */
    {0x36,0x49,0x49,0x49,0x36}, /* 8 */
    {0x26,0x49,0x49,0x49,0x3E}, /* 9 */
    {0x08,0x08,0x08,0x08,0x08}, /* : */
    {0x00,0x36,0x36,0x00,0x00}, /* - */
    {0x20,0x10,0x08,0x04,0x02}, /* . */
    {0x00,0x60,0x60,0x00,0x00}, /* / */
    {0x02,0x01,0x59,0x09,0x06}  /* ? */
};

static const char *MENU_LABELS[MENU_ITEMS] = {
    "START VITA3K",
    "CONTROLLER TEST",
    "EXIT TO HOME"
};

static void set_color(SDL_Renderer *renderer, Uint8 r, Uint8 g, Uint8 b)
{
    SDL_SetRenderDrawColor(renderer, r, g, b, 255);
}

static void fill_rect(SDL_Renderer *renderer, int x, int y, int w, int h,
                      Uint8 r, Uint8 g, Uint8 b)
{
    SDL_Rect rect = {x, y, w, h};
    set_color(renderer, r, g, b);
    SDL_RenderFillRect(renderer, &rect);
}

static const unsigned char *glyph_for(char character)
{
    const char *found;
    character = (char)toupper((unsigned char)character);
    found = strchr(FONT_CHARS, character);
    if (found == NULL)
        return NULL;
    return FONT_GLYPHS[(size_t)(found - FONT_CHARS)];
}

static void draw_text(SDL_Renderer *renderer, int x, int y, int scale,
                      Uint8 r, Uint8 g, Uint8 b, const char *text)
{
    int cursor_x = x;
    const char *cursor;

    set_color(renderer, r, g, b);
    for (cursor = text; *cursor != '\0'; ++cursor) {
        const unsigned char *glyph;
        int column;
        if (*cursor == ' ') {
            cursor_x += 4 * scale;
            continue;
        }
        glyph = glyph_for(*cursor);
        if (glyph != NULL) {
            for (column = 0; column < 5; ++column) {
                int row;
                for (row = 0; row < 7; ++row) {
                    if ((glyph[column] & (1U << row)) != 0) {
                        SDL_Rect pixel = {
                            cursor_x + column * scale,
                            y + row * scale,
                            scale,
                            scale
                        };
                        SDL_RenderFillRect(renderer, &pixel);
                    }
                }
            }
        }
        cursor_x += 6 * scale;
    }
}

static void draw_centered(SDL_Renderer *renderer, int center_x, int y, int scale,
                          Uint8 r, Uint8 g, Uint8 b, const char *text)
{
    size_t length = strlen(text);
    int width = length == 0 ? 0 : (int)(length * 6 * (size_t)scale - scale);
    draw_text(renderer, center_x - width / 2, y, scale, r, g, b, text);
}

static void draw_ui(SDL_Renderer *renderer, int selected, bool controller_found,
                    const char *status)
{
    int i;
    fill_rect(renderer, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, 9, 14, 29);

    /* Background accents, intentionally drawn without textures or shaders. */
    fill_rect(renderer, 0, 0, WINDOW_WIDTH, 8, 49, 212, 225);
    fill_rect(renderer, 0, 8, 18, WINDOW_HEIGHT - 8, 49, 212, 225);
    fill_rect(renderer, 80, 172, 1120, 2, 32, 54, 83);
    fill_rect(renderer, 80, 184, 300, 4, 108, 92, 245);

    draw_text(renderer, 90, 62, 5, 240, 246, 255, "VITAPS4");
    draw_text(renderer, 92, 112, 2, 130, 213, 233, "NATIVE PS4 HOME BREW SHELL");
    draw_text(renderer, 824, 80, 2,
              controller_found ? 90 : 240,
              controller_found ? 225 : 182,
              controller_found ? 168 : 155,
              controller_found ? "CONTROLLER OK" : "NO CONTROLLER");

    draw_text(renderer, 180, 211, 2, 174, 187, 210, "VITA3K PORT BOOTSTRAP");
    for (i = 0; i < MENU_ITEMS; ++i) {
        int y = 255 + i * 98;
        if (i == selected) {
            fill_rect(renderer, 174, y, 932, 78, 31, 68, 91);
            fill_rect(renderer, 174, y, 7, 78, 49, 212, 225);
            fill_rect(renderer, 174, y, 932, 2, 49, 212, 225);
            draw_text(renderer, 214, y + 27, 3, 246, 252, 255, MENU_LABELS[i]);
            draw_text(renderer, 1018, y + 29, 2, 49, 212, 225, ">");
        } else {
            fill_rect(renderer, 174, y, 932, 78, 17, 27, 48);
            fill_rect(renderer, 174, y, 932, 1, 35, 50, 72);
            draw_text(renderer, 214, y + 27, 3, 160, 177, 200, MENU_LABELS[i]);
        }
    }

    fill_rect(renderer, 174, 565, 932, 44, 16, 25, 43);
    draw_text(renderer, 193, 580, 2, 102, 222, 215, status);

    fill_rect(renderer, 174, 629, 932, 1, 39, 58, 82);
    draw_text(renderer, 180, 650, 2, 140, 158, 185,
              "DPAD UP DOWN MOVE  CROSS SELECT  OPTIONS EXIT");
}

static void move_selection(int *selected, int delta)
{
    *selected = (*selected + delta + MENU_ITEMS) % MENU_ITEMS;
}

static void activate_selection(int selected, bool controller_found,
                               char *status, size_t status_size, bool *running)
{
    if (selected == 0) {
        snprintf(status, status_size, "VITA3K CORE NOT LINKED YET");
    } else if (selected == 1) {
        snprintf(status, status_size, "%s",
                 controller_found ? "CONTROLLER INPUT IS READY" : "NO CONTROLLER DETECTED");
    } else {
        *running = false;
    }
}

int main(int argc, char **argv)
{
    SDL_Window *window = NULL;
    SDL_Surface *window_surface = NULL;
    SDL_Renderer *renderer = NULL;
    SDL_Joystick *controller = NULL;
    SDL_Event event;
    bool running = true;
    int selected = 0;
    char status[64] = "CORE NOT LINKED - SHELL TEST ONLY";
    (void)argc;
    (void)argv;

    setvbuf(stdout, NULL, _IONBF, 0);
    printf("VitaPS4 shell: initializing SDL2. This is not the Vita3K emulator.\n");

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK) != 0) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_JoystickEventState(SDL_ENABLE);
    if (SDL_NumJoysticks() > 0)
        controller = SDL_JoystickOpen(0);

    window = SDL_CreateWindow("VitaPS4 - Native Shell",
                              SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                              WINDOW_WIDTH, WINDOW_HEIGHT, 0);
    if (window == NULL) {
        fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
        if (controller != NULL)
            SDL_JoystickClose(controller);
        SDL_Quit();
        return 2;
    }

    window_surface = SDL_GetWindowSurface(window);
    if (window_surface == NULL) {
        fprintf(stderr, "SDL_GetWindowSurface failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        if (controller != NULL)
            SDL_JoystickClose(controller);
        SDL_Quit();
        return 3;
    }

    renderer = SDL_CreateSoftwareRenderer(window_surface);
    if (renderer == NULL) {
        fprintf(stderr, "SDL_CreateSoftwareRenderer failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        if (controller != NULL)
            SDL_JoystickClose(controller);
        SDL_Quit();
        return 4;
    }

    while (running) {
        while (SDL_PollEvent(&event) != 0) {
            if (event.type == SDL_QUIT) {
                running = false;
            } else if (event.type == SDL_KEYDOWN) {
                switch (event.key.keysym.sym) {
                case SDLK_UP:
                    move_selection(&selected, -1);
                    break;
                case SDLK_DOWN:
                    move_selection(&selected, 1);
                    break;
                case SDLK_RETURN:
                case SDLK_SPACE:
                    activate_selection(selected, controller != NULL,
                                       status, sizeof(status), &running);
                    break;
                case SDLK_ESCAPE:
                    running = false;
                    break;
                default:
                    break;
                }
            } else if (event.type == SDL_JOYBUTTONDOWN) {
                if (event.jbutton.button == PAD_UP) {
                    move_selection(&selected, -1);
                } else if (event.jbutton.button == PAD_DOWN) {
                    move_selection(&selected, 1);
                } else if (event.jbutton.button == PAD_CROSS) {
                    activate_selection(selected, controller != NULL,
                                       status, sizeof(status), &running);
                } else if (event.jbutton.button == PAD_OPTIONS) {
                    running = false;
                }
            } else if (event.type == SDL_JOYHATMOTION) {
                if (event.jhat.value & SDL_HAT_UP)
                    move_selection(&selected, -1);
                else if (event.jhat.value & SDL_HAT_DOWN)
                    move_selection(&selected, 1);
            }
        }

        draw_ui(renderer, selected, controller != NULL, status);
        SDL_RenderPresent(renderer);
        if (SDL_UpdateWindowSurface(window) != 0) {
            fprintf(stderr, "SDL_UpdateWindowSurface failed: %s\n", SDL_GetError());
            break;
        }
        SDL_Delay(16);
    }

    if (renderer != NULL)
        SDL_DestroyRenderer(renderer);
    if (window != NULL)
        SDL_DestroyWindow(window);
    if (controller != NULL)
        SDL_JoystickClose(controller);
    SDL_Quit();
    printf("VitaPS4 shell: clean exit.\n");
    return 0;
}
