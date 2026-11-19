#!/bin/sh
# QB64-PE installer for Haiku x86_64 (and RenkuOS)
#
# Required packages (HaikuPorts):
#   pkgman install gcc mesa_devel glu_devel openal_devel
#
# GLUT is part of Haiku itself (libglut, a GLUT 3.7 implementation), GLU comes
# from the Haiku 'glu' package and OpenAL Soft from HaikuPorts. The bundled
# FreeGLUT and GLEW sources are not used: Mesa's libGL exports the GL_EXT entry
# points directly, and because Haiku's GLUT has no FreeGLUT extensions
# CORE_FREEGLUT is not defined either.
#
# Unlike the legacy tree this needs no separate bootstrap stage: internal/c/qbx.cpp
# includes the pre-generated compiler sources from internal/source, which the
# Makefile copies into internal/temp when BUILD_QB64 is set.

set -e

if [ "$(uname -s)" != "Haiku" ]; then
	echo "This script builds QB64-PE for Haiku; run it under Haiku."
	exit 1
fi

cd "$(dirname "$0")"

# The compiler is generated as a single enormous translation unit, so GCC needs
# a large stack for code of that size.
ulimit -s 65536 2>/dev/null || true

mkdir -p internal/temp

jobs="$(sysinfo -cpu 2>/dev/null | grep -c '^CPU #' || true)"
if [ -z "$jobs" ] || [ "$jobs" -lt 1 ] 2>/dev/null; then
	jobs=2
fi
if [ "$jobs" -gt 8 ]; then
	jobs=8
fi

echo "Cleaning previous build"
# Wipe internal/temp outright: make clean leaves behind any file whose name
# contains a space (the stray " 2.txt" duplicates of 3.4.0), and a leftover
# "data10 2.txt" breaks the qbx.o dependency list because make splits it on
# the space.
rm -rf internal/temp
mkdir -p internal/temp
make clean OS=hai >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# GCC 13 on Haiku can abort with "internal compiler error: Segmentation
# violation" while compiling the generated compiler sources; it happens inside
# the register allocator on functions with tens of thousands of statements.
# The retry lowers the peak memory the compiler needs and drops the stack
# protector, which avoids that class of crash.
# ---------------------------------------------------------------------------
echo "Building QB64-PE"
if ! make OS=hai BUILD_QB64=y -j"$jobs"; then
	echo ""
	echo "The build failed. If the error was an internal compiler error in g++,"
	echo "retrying with a smaller compiler footprint and without the stack protector."
	make OS=hai BUILD_QB64=y -j1 \
		CXXFLAGS_EXTRA="-fno-stack-protector --param ggc-min-expand=0 --param ggc-min-heapsize=0"
fi

if [ -x ./qb64pe ]; then
	echo "Done compiling!"
	echo "Run ./qb64pe to start the IDE, or ./qb64pe -c file.bas to compile a program."
else
	echo "It appears that the qb64pe executable was not created; check the errors above."
	echo "Most failures are missing packages: gcc, mesa_devel, glu_devel, openal_devel."
	exit 1
fi
