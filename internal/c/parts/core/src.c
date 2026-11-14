//Haiku only: GLEW, GLU and GLUT all come from the system
//(HaikuPorts glew_devel and glu_devel, plus the GLUT built into Haiku).
#ifndef QB64_GLES
 #include <GL/glew.h>
#endif

#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
