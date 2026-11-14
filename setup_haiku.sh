#!/bin/sh
# QB64 installer for Haiku x86_64
#
# Required packages (HaikuPorts):
#   pkgman install gcc mesa_devel glu_devel glew_devel openal_devel
#
# GLUT is shipped with Haiku itself (libglut), OpenAL is the HaikuPorts build
# which includes a native Media Kit backend, and GLEW comes from HaikuPorts.
#
# The build has two stages, exactly like the upstream CI:
#   1. link a bootstrap IDE from the precompiled IDE sources in internal/source
#   2. let that bootstrap compile source/qb64.bas (-z: C++ only) and link the
#      resulting Haiku-aware IDE
# Stage 2 is required because the precompiled internal/source IDE was generated
# on Linux and still contains the Linux platform selection logic.

set -e

if [ "$(uname -s)" != "Haiku" ]; then
	echo "This script builds QB64 for Haiku; run it under Haiku."
	exit 1
fi

cd "$(dirname "$0")"

# The IDE is generated as a single enormous translation unit
# (internal/temp/main.txt: about 8 MB, 200,000 lines, with functions of 12,000
# lines). GCC needs a large stack for code that size.
ulimit -s 65536 2>/dev/null || true

# Make sure the runtime part directories exist (the IDE rebuilds part archives
# on demand the first time a program needs them).
for dir in \
	internal/c/parts/core/os/haiku \
	internal/c/parts/video/font/ttf/os/haiku \
	internal/c/parts/audio/conversion/os/haiku/temp \
	internal/c/parts/audio/decode/mp3_mini/os/haiku/temp \
	internal/c/parts/audio/decode/ogg/os/haiku \
	internal/c/parts/audio/out/os/haiku \
	internal/c/parts/input/game_controller/os/haiku/temp \
	internal/temp
do
	mkdir -p "$dir"
done

find . -name "*.sh" -exec chmod +x {} \;
find internal/c/parts -type f \( -iname "*.a" -o -iname "*.o" \) -exec rm -f {} \;
rm -f internal/temp/* 2>/dev/null || true

echo "Building library 'LibQB'"
cd internal/c/libqb/os/haiku
rm -f libqb_setup.o
./setup_build.sh
cd - > /dev/null

echo "Building library 'FreeType'"
cd internal/c/parts/video/font/ttf/os/haiku
rm -f src.o
./setup_build.sh
cd - > /dev/null

echo "Building library 'Core:GLUT'"
cd internal/c/parts/core/os/haiku
./setup_build.sh
cd - > /dev/null

# ---------------------------------------------------------------------------
# GCC 13 on Haiku can abort with "internal compiler error: Segmentation
# violation" while compiling the generated IDE source. It happens inside the
# RTL passes (ira, pro_and_epilogue) and at different places on each run, which
# points at the register allocator running out of resources on functions with
# tens of thousands of statements - not at a defect in the generated code, and
# not at anything specific to Haiku's platform files. The retry below lowers the
# peak memory the compiler needs and drops the stack protector, which avoids
# that class of crash.
# ---------------------------------------------------------------------------
CXX="${CXX:-g++}"
IDE_OBJECTS="libqb/os/haiku/libqb_setup.o parts/video/font/ttf/os/haiku/src.o parts/core/os/haiku/src.a"
IDE_LIBS="-lGL -lGLU -lglut -lGLEW -lbe -lnetwork"

build_ide() {
	output="$1"
	cd internal/c
	if "$CXX" -no-pie -w qbx.cpp $IDE_OBJECTS $IDE_LIBS -o "$output"; then
		cd ../..
		return 0
	fi
	echo ""
	echo "'$CXX' crashed while compiling the generated IDE source."
	echo "Retrying with a smaller compiler footprint and without the stack"
	echo "protector; this pass is slower but uses much less memory."
	case "$CXX" in
		*clang*)
			retry_flags="-fno-stack-protector"
			;;
		*)
			retry_flags="-fno-stack-protector --param ggc-min-expand=0 --param ggc-min-heapsize=0"
			;;
	esac
	# shellcheck disable=SC2086
	"$CXX" -no-pie -w $retry_flags qbx.cpp $IDE_OBJECTS $IDE_LIBS -o "$output"
	cd ../..
}

# ---------------------------------------------------------------------------
# Stage 1: bootstrap IDE from the bundled precompiled IDE sources
# ---------------------------------------------------------------------------
echo "Building 'QB64' bootstrap"
cp -r ./internal/source/* ./internal/temp/
build_ide ../../qb64_bootstrap

# ---------------------------------------------------------------------------
# Stage 2: recompile the IDE itself from source/qb64.bas
#
# The bootstrap comes from internal/source, which upstream last regenerated in
# 2022, so it is older than source/qb64.bas. It occasionally reports a bogus
# "SUB not found" at the very end of a successful C++ generation. If that
# happens but main.txt really was rewritten, use the generated sources and let
# the C++ compiler have the final word.
# ---------------------------------------------------------------------------
echo "Compiling the IDE from source/qb64.bas"
before_main="$(cksum internal/temp/main.txt 2>/dev/null | awk '{print $1 ":" $2}')"
if ./qb64_bootstrap -z -w source/qb64.bas; then
	:
else
	after_main="$(cksum internal/temp/main.txt 2>/dev/null | awk '{print $1 ":" $2}')"
	if [ "$before_main" != "$after_main" ]; then
		echo ""
		echo "The bootstrap reported an error after generating the C++ sources."
		echo "internal/temp/main.txt was rewritten anyway, so continuing; the C++"
		echo "compiler will reject anything that is actually wrong."
	else
		echo ""
		echo "Generating the IDE sources failed and internal/temp was not updated."
		exit 1
	fi
fi

echo "Building 'QB64'"
build_ide ../../qb64

rm -f qb64_bootstrap

if [ -e "./qb64" ]; then
	echo "Done compiling!"
	echo "Run ./qb64 to start the IDE, or ./qb64 -c file.bas to compile a program."
else
	echo "It appears that the qb64 executable was not created; check the errors above."
	echo "Most failures are missing packages: gcc, mesa_devel, glu_devel, glew_devel, openal_devel."
	exit 1
fi
