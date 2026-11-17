cmake_minimum_required(VERSION 3.18)

project(qb64_haiku C CXX)

# This build produces the QB64 IDE/compiler bootstrap binary
# (qb64_bootstrap) on Haiku. Compiled BASIC programs are built by the IDE
# itself through internal/c/makeline_haiku.txt.

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Haiku")
	message(FATAL_ERROR
		"This CMake project builds QB64 for Haiku. Run it on Haiku, or use "
		"./setup_haiku.sh.")
endif()

set(QB64_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(QB64_C    "${QB64_ROOT}/internal/c")

# ---------------------------------------------------------------------------
# qbx.cpp includes the precompiled IDE sources from ../temp, so stage them.
# ---------------------------------------------------------------------------
file(GLOB QB64_IDE_SOURCES "${QB64_ROOT}/internal/source/*")

add_custom_target(qb64_stage ALL
	COMMAND "${CMAKE_COMMAND}" -E make_directory "${QB64_ROOT}/internal/temp"
	COMMAND "${CMAKE_COMMAND}" -E copy_if_different
		${QB64_IDE_SOURCES} "${QB64_ROOT}/internal/temp"
	COMMENT "Staging internal/source into internal/temp")

# ---------------------------------------------------------------------------
# Haiku system libraries (HaikuPorts: mesa_devel, glu_devel, glew_devel).
# ---------------------------------------------------------------------------
find_library(GL_LIBRARY   NAMES GL   REQUIRED)
find_library(GLU_LIBRARY  NAMES GLU  REQUIRED)
find_library(GLUT_LIBRARY NAMES glut REQUIRED)
find_library(GLEW_LIBRARY NAMES GLEW REQUIRED)
find_library(BE_LIBRARY   NAMES be   REQUIRED)
# Sockets and name resolution live in libnetwork, not libc, on Haiku.
find_library(NETWORK_LIBRARY NAMES network REQUIRED)

# LibQB runtime, compiled exactly like libqb/os/haiku/setup_build.sh
add_library(qb64_libqb OBJECT "${QB64_C}/libqb.cpp")
target_include_directories(qb64_libqb PRIVATE "${QB64_C}")
target_compile_options(qb64_libqb PRIVATE -w)
target_compile_definitions(qb64_libqb PRIVATE DEPENDENCY_LOADFONT)

# Embedded FreeType used for font rendering
add_library(qb64_freetype OBJECT
	"${QB64_C}/parts/video/font/ttf/src/freetypeamalgam.c")
target_include_directories(qb64_freetype PRIVATE
	"${QB64_C}/parts/video/font/ttf/src" "${QB64_C}")
target_compile_options(qb64_freetype PRIVATE -w)

add_executable(qb64_bootstrap
	"${QB64_C}/qbx.cpp"
	$<TARGET_OBJECTS:qb64_libqb>
	$<TARGET_OBJECTS:qb64_freetype>)

add_dependencies(qb64_bootstrap qb64_stage)

target_include_directories(qb64_bootstrap PRIVATE "${QB64_C}")
target_compile_options(qb64_bootstrap PRIVATE -w -fno-stack-protector)
target_compile_definitions(qb64_bootstrap PRIVATE DEPENDENCY_USER_MODS)
target_link_options(qb64_bootstrap PRIVATE -no-pie)
target_link_libraries(qb64_bootstrap PRIVATE
	${GLUT_LIBRARY} ${GLU_LIBRARY} ${GL_LIBRARY} ${GLEW_LIBRARY} ${BE_LIBRARY}
	${NETWORK_LIBRARY})

# Keep the binary where QB64 expects to find it (repository root).
set_target_properties(qb64_bootstrap PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${QB64_ROOT}")

# ---------------------------------------------------------------------------
# The bundled internal/source IDE was generated on Linux, so it does not know
# about the Haiku platform selection in source/qb64.bas. Use the bootstrap to
# recompile that source (-z: generate C++ only) and link the real IDE against
# Haiku's libraries.
# ---------------------------------------------------------------------------
add_custom_target(qb64_ide_generate
	COMMAND "${CMAKE_COMMAND}" -E chdir "${QB64_ROOT}"
		"./qb64_bootstrap" -z -w source/qb64.bas
	COMMENT "Compiling source/qb64.bas into the Haiku IDE sources")
add_dependencies(qb64_ide_generate qb64_bootstrap)

add_executable(qb64_ide
	"${QB64_C}/qbx.cpp"
	$<TARGET_OBJECTS:qb64_libqb>
	$<TARGET_OBJECTS:qb64_freetype>)

add_dependencies(qb64_ide qb64_ide_generate)

target_include_directories(qb64_ide PRIVATE "${QB64_C}")
target_compile_options(qb64_ide PRIVATE -w -fno-stack-protector)
target_compile_definitions(qb64_ide PRIVATE DEPENDENCY_USER_MODS)
target_link_options(qb64_ide PRIVATE -no-pie)
target_link_libraries(qb64_ide PRIVATE
	${GLUT_LIBRARY} ${GLU_LIBRARY} ${GL_LIBRARY} ${GLEW_LIBRARY} ${BE_LIBRARY}
	${NETWORK_LIBRARY})

set_target_properties(qb64_ide PROPERTIES
	OUTPUT_NAME qb64
	RUNTIME_OUTPUT_DIRECTORY "${QB64_ROOT}")

add_custom_target(qb64-clean
	COMMAND "${CMAKE_COMMAND}" -E rm -f
		"${QB64_ROOT}/qb64_bootstrap" "${QB64_ROOT}/qb64"
	COMMENT "Removing the generated QB64 binaries")
