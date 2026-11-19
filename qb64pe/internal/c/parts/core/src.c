#ifdef QB64_HAIKU
// Haiku ships GLUT (a GLUT 3.7 implementation) and Mesa's libGL. Mesa exports
// the GL_EXT entry points directly, so <GL/glext.h> prototypes are used instead
// of GLEW: Haiku's glext.h and glew.h declare conflicting typedefs, and GLEW
// would need glXGetProcAddress, which Haiku does not have. The bundled FreeGLUT
// and GLEW headers are not used, and CORE_FREEGLUT is deliberately not defined.
#    include <GL/gl.h>
#    include <GL/glut.h>
#    include <GL/glext.h>
#    include <GL/glu.h>
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
