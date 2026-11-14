# QB64 on Haiku (x86_64)

This port adds Haiku as a first-class QB64 platform. The IDE, the BASIC
compiler and the generated executables all build natively on Haiku; no X11,
no ALSA and no glibc assumptions are involved.

**This branch is Haiku-only.** Windows, Linux and macOS build support has
been removed; only Haiku x86_64 is built and supported. See
[Removed for the Haiku-only fork](#removed-for-the-haiku-only-fork).

## Requirements

Install the toolchain and development packages with `pkgman`:

```
pkgman install gcc mesa_devel glu_devel glew_devel openal_devel
```

* **GLUT** is provided by Haiku itself (`libglut`, built on the Game/Media
  kits). The bundled FreeGLUT in `internal/c/parts/core` is not used on Haiku.
* **OpenAL** comes from HaikuPorts (`openal`). That build contains the Haiku
  Media Kit backend, so `_SNDOPEN`, `PLAY`, `SOUND` and the other audio
  statements work through it.
* **GLEW** comes from HaikuPorts (`glew`).

## Building

Either use the bootstrap script:

```
./setup_haiku.sh
```

or CMake:

```
mkdir build && cd build && cmake .. && make
```

Both produce `qb64`. The build is two-stage, matching the upstream CI:

1. a bootstrap IDE is linked from the precompiled IDE sources in
   `internal/source` (CMake target `qb64_bootstrap`);
2. that bootstrap compiles `source/qb64.bas` with `-z` (C++ generation only),
   and the resulting sources are linked against Haiku's libraries into the
   real `qb64` IDE (CMake target `qb64_ide`, output name `qb64`).

Stage 2 is required whenever the IDE's BASIC source changes: the bundled
`internal/source` was generated on Linux and still contains the old platform
selection logic, so without recompiling it the IDE would look for
`parts/core/os/lnx` and `-ldl`/`-lrt`. `make clean` removes the objects,
`make qb64-clean` removes both generated binaries.

The first time a BASIC program that uses a subsystem (audio, gamepads, FreeType)
is compiled, the IDE builds the matching archive in
`internal/c/parts/*/os/haiku/` by running that directory's `build.sh`.

### If the build dies with "internal compiler error"

GCC 13 on Haiku can abort with `internal compiler error: Segmentation violation`
inside its RTL passes (`ira`, `pro_and_epilogue`) while compiling
`internal/temp/main.txt`, the roughly 8 MB, 200,000-line translation unit the
QB64 compiler generates for the IDE. The crash lands in a different pass and at
a different function on each run, which is the signature of the compiler
running out of resources on very large functions rather than of a problem in
the generated code: the same file builds on Linux and macOS.

`setup_haiku.sh` detects that failure and retries the compile with
`-fno-stack-protector` and, for GCC, `--param ggc-min-expand=0
--param ggc-min-heapsize=0`. The retry makes the compiler collect garbage
constantly, so it needs much less memory but takes several minutes; it only
runs when the normal attempt failed. The CMake build always passes
`-fno-stack-protector`. If both still crash, the machine is short of RAM for
this file: free memory, or set `CXX` to a Clang from HaikuPorts and rebuild.

## Platform implementation notes

| Area | Haiku implementation |
| --- | --- |
| OS detection | `__HAIKU__` defines `QB64_HAIKU`, `QB64_UNIX` and `QB64_GCC` in `internal/c/os.h` |
| `_OS$` | `[HAIKU][64BIT][LINUX]` so existing POSIX-oriented BASIC code keeps working; the IDE tests `[HAIKU]` before `[LINUX]` |
| Windows | Haiku's system GLUT (`<GL/glut.h>`); no FreeGLUT |
| OpenGL extensions | system GLEW (`<GL/glew.h>`), the bundled X11 GLEW is skipped |
| Sound | system OpenAL (`<AL/al.h>`, `-lopenal`) |
| Clipboard | `BClipboard` (system clipboard) |
| Message boxes | `BAlert`; console-only builds print to stderr |
| Executable directory | `get_next_image_info()` (Haiku has no `/proc/self/exe`) |
| Monotonic clock | `clock_gettime(CLOCK_MONOTONIC)` |
| Keyboard | Haiku's `libglut` reports Return as LF (10); `libqb` normalizes it to CR (13) so Enter works without Ctrl |
| Gamepads | `BJoystick` (Haiku device kit) in `Gamepad_haiku.c` |
| Embedded `$DATA` | `objcopy -Ibinary -Oelf64-x86-64 -Bi386:x86-64` |

### Deliberate limitations

* Haiku's GLUT has no mouse-wheel callback (that is a FreeGLUT extension), so
  the IDE is scrolled with the arrow/Page keys and the scrollbar instead.
* The Linux-only probing of `/usr/lib` and `/usr/include` when declaring
  external `$LIBRARY` files does not find Haiku's package-managed locations.
  Pass an explicit path, or link through libraries that are in the compiler's
  default search path.
* The IDE and BASIC compilation were exercised on Haiku x86_64. The
  remaining IDE interface glitches are cosmetic, not build-system issues.

## Removed for the Haiku-only fork

The Windows MinGW-w64 toolchains (`internal/c/mingw32` and
`internal/c/mingw64`, 1.1 GB of binaries) have been removed. They were only
ever used by `setup_win.bat`, which renames one of them to
`internal/c/c_compiler`; on Haiku the compiler is the system `g++` from
HaikuPorts, and no Haiku build file referred to them.

Windows, Linux and macOS build files are gone as well: the `os/lnx`, `os/osx`
and `os/win` build trees, `setup_lnx.sh`, `setup_osx.command`, `setup_win.bat`,
the `makeline_*`/`makedat_*` variants for those systems, the `.ci` scripts, the
bundled FreeGLUT/GLEW/OpenAL Soft sources, the foreign gamepad backends and the
`download/` snapshots.

`source/qb64.bas` still contains some unreachable `os$ = "WIN"` code paths (for
example the `c_compiler` based compile step). They never execute on Haiku, but
pruning them is a separate refactor because the file cannot be syntax-checked
without a full IDE rebuild.



# QB64 development build - Changelog
Upcoming version is currently identified as v2.1, but that number may change before release.

## New features
### All platforms
- Implement the `_Bin$` function as counterpart to `&B` prefixed number strings. Usage is analog to the legacy OCT$ and HEX$ functions.
- Save Watch Panel position and size.
- Add `$NOPREFIX` support for `$COLOR`.
- Allow changing color of menu panels and dialogs (Options->IDE Colors).
- Add support to different number formats in Watch Panel and Watch List dialog (dec/hex/oct/bin).

<!--- 
### Windows

### macOS

### Linux
--->

## Fixes
### All platforms
- Fix function `LOC` returning wrong values when used on physical files.
- Fix glitch in syntax highlighter mistaking variable names with scientific notation.
- Fix Variable List dialog's "Add All" button not properly considering the active filter.
- Fix wiki update feature.
- Fix issue with Sub/Function parameters in `Declare` blocks with `$NoPrefix`.
- Fix issue with Sub/Function parameters without types after `As`.
- Fix issue with capitalization of array names in `LBound/UBound` calls.
- Fix capitalization of 'To' in `Case` statements.
- Fix indentation issue in disabled precompiler blocks.
- Fix crash when a variable was deleted between `$Debug` sessions.
- Reenables selecting a line by clicking the line number bar when `$Debug` is not used and the `Auto-add $Debug metacommand` feature is disabled.

<!---
### Windows

### macOS
--->

### Linux
- Fix building static libraries when installation path contains spaces.
