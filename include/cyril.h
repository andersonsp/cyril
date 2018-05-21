#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>



#define cy_new(struct_type, n_structs)   \
( (struct_type *) malloc((sizeof(struct_type)) * (n_structs)) )

#define cy_new0(struct_type, n_structs) \
( (struct_type *) calloc((n_structs), (sizeof(struct_type))) )

#define cy_renew(struct_type, mem, n_structs)  \
( (struct_type *) realloc((mem), (sizeof(struct_type)) * (n_structs)) )

#define cy_free( pointer ) free( pointer )




// PAK file handling

typedef struct _CyPak CyPak;
typedef struct { int32_t size; uint8_t data[4]; } CyPakEntry;

CyPak* cy_pak_load(char* filename);
CyPakEntry* cy_pak_get(CyPak* pak, char* path);
void cy_pak_print_stats(CyPak* pak);


//
// Sysytem
//

typedef struct _CyWindow CyWindow;

typedef enum { // key definitions
  CY_KEY_UNKNOWN,
  CY_KEY_Q,
  CY_KEY_W,
  CY_KEY_E,
  CY_KEY_A,
  CY_KEY_S,
  CY_KEY_D,
  CY_KEY_ARROW_UP,
  CY_KEY_ARROW_DOWN,
  CY_KEY_ARROW_LEFT,
  CY_KEY_ARROW_RIGHT,
  CY_KEY_SPACE,
  CY_KEY_RETURN,
  CY_KEY_ESCAPE,
  CY_KEY_KEY_MAX
} CyKey;

typedef enum {
    CY_KEY_UP,
    CY_KEY_DOWN,
    CY_LEFT_MOUSE_UP,
    CY_LEFT_MOUSE_DOWN,
    CY_RIGHT_MOUSE_UP,
    CY_RIGHT_MOUSE_DOWN,
    CY_MOUSE_MOVE,
    CY_MOUSE_WHEEL,
    CY_GAMEPAD,
    CY_TIMER
} CyEventType;

typedef struct {
    CyEventType type;
    union {
        struct { int32_t code; } key;
        struct { int32_t x, y, dx, dy; } mouse;
        struct { int16_t digital; } gamepad;
        struct { int32_t ms; } timer;
    } data;
} CyEvent;

typedef struct { float w, h; } CyGeom;



// callbacks

typedef void (*CyOnEvent)(CyEvent *ev);
typedef void (*CyOnDisplay)(int width, int height);


int cy_init();
CyGeom cy_window(char* title, int x, int y, int w, int h, CyOnDisplay display_cb, CyOnEvent event_cb);
void cy_timer(int enable, int ms);
int64_t cy_abs_time();
int cy_main();
void cy_terminate();

/*
int main() {
    cy_init();
    geom = cy_window(...);

    // extra initialization needed
    // load resources etc

    glViewport(geom.w, gemo.h);

    cy_timer();  // if we want timed events to be fired

    // cy_main is the last function to be called, in some systems it does not return control to the caller
    return cy_main();
}
*/

