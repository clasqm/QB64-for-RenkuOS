cmake_minimum_required(VERSION 3.18)

project(qb64pe C CXX)

# ---------------------------------------------------------------------------
# QB64 Phoenix Edition for Haiku / RenkuOS
#
# An alternative to ./setup_haiku.sh - both produce the same ./qb64pe compiler
# binary. The IDE compiles BASIC programs itself through the Makefile in this
# directory, so this project only has to build the compiler.
#
#   mkdir build && cd build && cmake .. && make
#   # or: cmake -S . -B build && cmake --build build
#
# Packages: pkgman install gcc mesa_devel glu_devel openal_devel
# ---------------------------------------------------------------------------

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Haiku")
	message(FATAL_ERROR
		"This CMake project builds QB64-PE for Haiku. Run it on Haiku, or use "
		"./setup_haiku.sh.")
endif()

set(QB64_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(QB64_C "${QB64_ROOT}/internal/c")
set(QB64_TEMP "${QB64_ROOT}/internal/temp")

# ---------------------------------------------------------------------------
# qbx.cpp includes the pre-compiler sources from ../temp, so stage
# internal/source into internal/temp before anything is compiled - the same
# copy the Makefile performs for 'make BUILD_QB64=y'.
# ---------------------------------------------------------------------------
file(GLOB QB64_IDE_SOURCES "${QB64_ROOT}/internal/source/*")
set(QB64_STAGE_STAMP "${QB64_TEMP}/.qb64pe-staged")

add_custom_command(
	OUTPUT "${QB64_STAGE_STAMP}"
	COMMAND "${CMAKE_COMMAND}" -E make_directory "${QB64_TEMP}"
	COMMAND "${CMAKE_COMMAND}" -E copy_if_different
		${QB64_IDE_SOURCES} "${QB64_TEMP}"
	COMMAND "${CMAKE_COMMAND}" -E touch "${QB64_STAGE_STAMP}"
	DEPENDS ${QB64_IDE_SOURCES}
	COMMENT "Staging internal/source into internal/temp")

add_custom_target(qb64pe_stage DEPENDS "${QB64_STAGE_STAMP}")

# ---------------------------------------------------------------------------
# Haiku system libraries. GLUT comes with the base system, GLU from the 'glu'
# package, and OpenAL Soft from HaikuPorts. The bundled FreeGLUT and GLEW are
# not used: Mesa's libGL exports the GL_EXT entry points directly, and Haiku's
# GLUT has no FreeGLUT extensions, so CORE_FREEGLUT is not defined either.
# ---------------------------------------------------------------------------
find_library(GL_LIBRARY      NAMES GL      REQUIRED)
find_library(GLU_LIBRARY     NAMES GLU     REQUIRED)
find_library(GLUT_LIBRARY    NAMES glut    REQUIRED)
find_library(OPENAL_LIBRARY  NAMES openal  REQUIRED)
find_library(BE_LIBRARY      NAMES be      REQUIRED)
find_library(NETWORK_LIBRARY NAMES network REQUIRED)

# ---------------------------------------------------------------------------
# The compiler is a single enormous translation unit (qbx.cpp plus the staged
# sources) linked against libqb. GCC needs a large stack for code of that size,
# which is why setup_haiku.sh raises 'ulimit -s' first; do the same here if a
# build dies with an internal compiler error.
# ---------------------------------------------------------------------------
add_executable(qb64pe
	"${QB64_C}/qbx.cpp"
	"${QB64_C}/libqb.cpp"
	"${QB64_C}/libqb/src/threading.cpp"
	"${QB64_C}/libqb/src/buffer.cpp"
	"${QB64_C}/libqb/src/filepath.cpp"
	"${QB64_C}/libqb/src/threading-posix.cpp"
	"${QB64_C}/parts/gui/gui.cpp"
	"${QB64_C}/parts/gui/tinyfiledialogs.c"
	"${QB64_C}/parts/video/font/ttf/src/freetypeamalgam.c")

add_dependencies(qb64pe qb64pe_stage)

set_source_files_properties("${QB64_C}/qbx.cpp"
	PROPERTIES OBJECT_DEPENDS "${QB64_STAGE_STAMP}")

target_include_directories(qb64pe PRIVATE "${QB64_C}/libqb/include")

target_compile_options(qb64pe PRIVATE
	-w
	-no-pie
	$<$<COMPILE_LANGUAGE:CXX>:-std=gnu++11>)

# The dependency set the Makefile uses for the compiler itself:
# BUILD_QB64 defines DEP_FONT, DEP_ICON, DEP_ICON_RC and DEP_SOCKETS.
target_compile_definitions(qb64pe PRIVATE
	DEPENDENCY_SOCKETS
	DEPENDENCY_NO_PRINTER
	DEPENDENCY_ICON
	DEPENDENCY_NO_SCREENIMAGE
	DEPENDENCY_LOADFONT)

# The file dialogs and GUI helpers are compiled as console-only code, exactly
# as parts/gui/build.mk does.
set_source_files_properties(
	"${QB64_C}/parts/gui/gui.cpp"
	"${QB64_C}/parts/gui/tinyfiledialogs.c"
	PROPERTIES
		COMPILE_DEFINITIONS DEPENDENCY_CONSOLE_ONLY
		COMPILE_OPTIONS -Wall)

target_link_options(qb64pe PRIVATE -no-pie)

target_link_libraries(qb64pe PRIVATE
	${GL_LIBRARY}
	${GLU_LIBRARY}
	${GLUT_LIBRARY}
	${OPENAL_LIBRARY}
	${BE_LIBRARY}
	${NETWORK_LIBRARY}
	pthread
	m)

# Keep the binary where QB64 expects to find it (repository root).
set_target_properties(qb64pe PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${QB64_ROOT}")
