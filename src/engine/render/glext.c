#include <glext.h>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN 1
#include <windows.h>
#define dlsym GetProcAddress
#else
#include <dlfcn.h>
#endif

PFNGLACTIVETEXTUREPROC glActiveTexture;
PFNGLATTACHSHADERPROC glAttachShader;
PFNGLBINDATTRIBLOCATIONPROC glBindAttribLocation;
PFNGLBINDBUFFERPROC glBindBuffer;
PFNGLBINDTEXTUREPROC glBindTexture;
PFNGLBLENDFUNCPROC glBlendFunc;
PFNGLBUFFERDATAPROC glBufferData;
PFNGLCLEARPROC glClear;
PFNGLCLEARCOLORPROC glClearColor;
PFNGLCLEARDEPTHPROC glClearDepth;
PFNGLCOMPILESHADERPROC glCompileShader;
PFNGLCREATEPROGRAMPROC glCreateProgram;
PFNGLCREATESHADERPROC glCreateShader;
PFNGLCULLFACEPROC glCullFace;
PFNGLDISABLEVERTEXATTRIBARRAYPROC glDisableVertexAttribArray;
PFNGLDRAWELEMENTSPROC glDrawElements;
PFNGLENABLEPROC glEnable;
PFNGLENABLEVERTEXATTRIBARRAYPROC glEnableVertexAttribArray;
PFNGLGENBUFFERSPROC glGenBuffers;
PFNGLGENTEXTURESPROC glGenTextures;
PFNGLGETPROGRAMIVPROC glGetProgramiv;
PFNGLGETSHADERINFOLOGPROC glGetShaderInfoLog;
PFNGLGETSHADERIVPROC glGetShaderiv;
PFNGLLINKPROGRAMPROC glLinkProgram;
PFNGLSHADERSOURCEPROC glShaderSource;
PFNGLTEXIMAGE2DPROC glTexImage2D;
PFNGLTEXPARAMETERIPROC glTexParameteri;
PFNGLUNIFORM1IPROC glUniform1i;
PFNGLUNIFORMMATRIX4FVPROC glUniformMatrix4fv;
PFNGLUSEPROGRAMPROC glUseProgram;
PFNGLVERTEXATTRIBPOINTERPROC glVertexAttribPointer;
PFNGLVIEWPORTPROC glViewport;

int glext_init() {
#ifdef _WIN32
  HMODULE libgl = LoadLibraryA("opengl32.dll");
#elif defined(__APPLE__) || defined(__APPLE_CC__)
  void* libgl = dlopen("/System/Library/Frameworks/OpenGL.framework/OpenGL", RTLD_LAZY | RTLD_GLOBAL);
#else
  void* libgl = dlopen("libGL.so.1", RTLD_LAZY | RTLD_GLOBAL);
#endif

  if(!libgl) return GLEXT_LIB_ERR;

  glActiveTexture = (PFNGLACTIVETEXTUREPROC) dlsym(libgl, "glActiveTexture");
  if(!glActiveTexture) return 1;
  glAttachShader = (PFNGLATTACHSHADERPROC) dlsym(libgl, "glAttachShader");
  if(!glAttachShader) return 2;
  glBindAttribLocation = (PFNGLBINDATTRIBLOCATIONPROC) dlsym(libgl, "glBindAttribLocation");
  if(!glBindAttribLocation) return 3;
  glBindBuffer = (PFNGLBINDBUFFERPROC) dlsym(libgl, "glBindBuffer");
  if(!glBindBuffer) return 4;
  glBindTexture = (PFNGLBINDTEXTUREPROC) dlsym(libgl, "glBindTexture");
  if(!glBindTexture) return 5;
  glBlendFunc = (PFNGLBLENDFUNCPROC) dlsym(libgl, "glBlendFunc");
  if(!glBlendFunc) return 6;
  glBufferData = (PFNGLBUFFERDATAPROC) dlsym(libgl, "glBufferData");
  if(!glBufferData) return 7;
  glClear = (PFNGLCLEARPROC) dlsym(libgl, "glClear");
  if(!glClear) return 8;
  glClearColor = (PFNGLCLEARCOLORPROC) dlsym(libgl, "glClearColor");
  if(!glClearColor) return 9;
  glClearDepth = (PFNGLCLEARDEPTHPROC) dlsym(libgl, "glClearDepth");
  if(!glClearDepth) return 10;
  glCompileShader = (PFNGLCOMPILESHADERPROC) dlsym(libgl, "glCompileShader");
  if(!glCompileShader) return 11;
  glCreateProgram = (PFNGLCREATEPROGRAMPROC) dlsym(libgl, "glCreateProgram");
  if(!glCreateProgram) return 12;
  glCreateShader = (PFNGLCREATESHADERPROC) dlsym(libgl, "glCreateShader");
  if(!glCreateShader) return 13;
  glCullFace = (PFNGLCULLFACEPROC) dlsym(libgl, "glCullFace");
  if(!glCullFace) return 14;
  glDisableVertexAttribArray = (PFNGLDISABLEVERTEXATTRIBARRAYPROC) dlsym(libgl, "glDisableVertexAttribArray");
  if(!glDisableVertexAttribArray) return 15;
  glDrawElements = (PFNGLDRAWELEMENTSPROC) dlsym(libgl, "glDrawElements");
  if(!glDrawElements) return 16;
  glEnable = (PFNGLENABLEPROC) dlsym(libgl, "glEnable");
  if(!glEnable) return 17;
  glEnableVertexAttribArray = (PFNGLENABLEVERTEXATTRIBARRAYPROC) dlsym(libgl, "glEnableVertexAttribArray");
  if(!glEnableVertexAttribArray) return 18;
  glGenBuffers = (PFNGLGENBUFFERSPROC) dlsym(libgl, "glGenBuffers");
  if(!glGenBuffers) return 19;
  glGenTextures = (PFNGLGENTEXTURESPROC) dlsym(libgl, "glGenTextures");
  if(!glGenTextures) return 20;
  glGetProgramiv = (PFNGLGETPROGRAMIVPROC) dlsym(libgl, "glGetProgramiv");
  if(!glGetProgramiv) return 21;
  glGetShaderInfoLog = (PFNGLGETSHADERINFOLOGPROC) dlsym(libgl, "glGetShaderInfoLog");
  if(!glGetShaderInfoLog) return 22;
  glGetShaderiv = (PFNGLGETSHADERIVPROC) dlsym(libgl, "glGetShaderiv");
  if(!glGetShaderiv) return 23;
  glLinkProgram = (PFNGLLINKPROGRAMPROC) dlsym(libgl, "glLinkProgram");
  if(!glLinkProgram) return 24;
  glShaderSource = (PFNGLSHADERSOURCEPROC) dlsym(libgl, "glShaderSource");
  if(!glShaderSource) return 25;
  glTexImage2D = (PFNGLTEXIMAGE2DPROC) dlsym(libgl, "glTexImage2D");
  if(!glTexImage2D) return 26;
  glTexParameteri = (PFNGLTEXPARAMETERIPROC) dlsym(libgl, "glTexParameteri");
  if(!glTexParameteri) return 27;
  glUniform1i = (PFNGLUNIFORM1IPROC) dlsym(libgl, "glUniform1i");
  if(!glUniform1i) return 28;
  glUniformMatrix4fv = (PFNGLUNIFORMMATRIX4FVPROC) dlsym(libgl, "glUniformMatrix4fv");
  if(!glUniformMatrix4fv) return 29;
  glUseProgram = (PFNGLUSEPROGRAMPROC) dlsym(libgl, "glUseProgram");
  if(!glUseProgram) return 30;
  glVertexAttribPointer = (PFNGLVERTEXATTRIBPOINTERPROC) dlsym(libgl, "glVertexAttribPointer");
  if(!glVertexAttribPointer) return 31;
  glViewport = (PFNGLVIEWPORTPROC) dlsym(libgl, "glViewport");
  if(!glViewport) return 32;
#ifdef _WIN32
  FreeLibrary(libgl);
#else
  dlclose(libgl);
#endif
  return 0;
}
