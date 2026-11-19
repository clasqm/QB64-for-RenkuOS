#!/bin/sh
# Haiku x86_64: GLUT and GLEW are provided by the system (libglut / libGLEW),
# so FREEGLUT_STATIC and the bundled freeglut are deliberately not used.
g++ -c -w -Wall ../../../libqb.cpp -D DEPENDENCY_LOADFONT -o libqb_setup.o
