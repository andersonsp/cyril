#include <cyril.h>
#include <glext.h>

static int pressing = 0;

#define WIDTH   640
#define HEIGHT  480


void on_display(int width, int height) {
  if (pressing) {
    glClearColor(1, 1, 0.75f, 1);
  } else {
    glClearColor(1, 1, 1, 1);
  }
  glClear(GL_COLOR_BUFFER_BIT);
}

void on_event(CyEvent* ev) {
  switch(ev->type) {
    case CY_LEFT_MOUSE_DOWN:
    case CY_RIGHT_MOUSE_DOWN:
      pressing = 1;
      break;
    case CY_LEFT_MOUSE_UP:
    case CY_RIGHT_MOUSE_UP:
      pressing = 0;
      break;
    case CY_KEY_DOWN:
      if(ev->data.key.code == CY_KEY_ESCAPE) cy_terminate();
      break;
    default:
      break;
      // do nothing
  }
}

int main(int argc, const char *argv[]) {
    cy_init();
    CyGeom geom = cy_window("test window", 0, 0, WIDTH, HEIGHT, on_display, on_event);

    // Initialize glext
    int res = glext_init();
    if(res != 0) {
        fprintf(stderr, "glext: failed to initialize: %d\n", res);
        exit(EXIT_FAILURE);
    }

    // extra initialization needed
    // load resources etc

    glViewport(0, 0, (GLsizei)geom.w, (GLsizei)geom.h);

    // cy_timer();  // if we want timed events to be fired

    // cy_main is the last function to be called, in some systems it does not return control to the caller
    return cy_main();
}
