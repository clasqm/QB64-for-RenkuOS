#ifdef QB64_HAIKU
// Haiku provides GLUT (a GLUT 3.7 implementation) and GLEW in the base
// system / HaikuPorts, so the bundled FreeGLUT and GLEW headers are not
// used here. Note that CORE_FREEGLUT is deliberately not defined.
#    include <GL/glut.h>
#    include <GL/glew.h>
#else
#ifndef QB64_GLES
#    include "glew/include/GL/glew.h"
#endif

#ifdef QB64_MACOSX
// note: MacOSX uses Apple's GLUT not FreeGLUT
#    include <GLUT/glut.h>
#    include <OpenGL/gl.h>
#    include <OpenGL/glext.h>
#    include <OpenGL/glu.h>
#else
#    define CORE_FREEGLUT
#    include "src/freeglut.h"
#endif
#endif // QB64_HAIKU
