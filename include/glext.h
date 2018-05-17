#ifndef GLEXT_H_H_INCLUDED
#define GLEXT_H_H_INCLUDED
#include <gl/glcorearb.h>

int glext_init(void* mod);
void* glext_proc_addr(void* mod, char* name);

extern PFNGLCLEARPROC glClear;
extern PFNGLCLEARCOLORPROC glClearColor;
extern PFNGLCULLFACEPROC glCullFace;
extern PFNGLVIEWPORTPROC glViewport;
#endif // GLEXT_H_H_INCLUDED
