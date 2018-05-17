#include <glext.h>

PFNGLCLEARPROC glClear;
PFNGLCLEARCOLORPROC glClearColor;
PFNGLCULLFACEPROC glCullFace;
PFNGLVIEWPORTPROC glViewport;

int glext_init(void* mod) {
  glClear = (PFNGLCLEARPROC) glext_proc_addr(mod, "glClear");
  if(!glClear) return 1;
  glClearColor = (PFNGLCLEARCOLORPROC) glext_proc_addr(mod, "glClearColor");
  if(!glClearColor) return 2;
  glCullFace = (PFNGLCULLFACEPROC) glext_proc_addr(mod, "glCullFace");
  if(!glCullFace) return 3;
  glViewport = (PFNGLVIEWPORTPROC) glext_proc_addr(mod, "glViewport");
  if(!glViewport) return 4;
  return 0;
}
