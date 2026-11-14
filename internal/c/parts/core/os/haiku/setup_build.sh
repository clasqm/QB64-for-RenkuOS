#!/bin/sh
# Haiku supplies GLUT itself (libglut, built on top of the Media/Game kits),
# therefore there is no bundled FreeGLUT to build. An empty archive keeps the
# link line in sync with the other platforms.
rm -f src.a
ar rcs src.a
