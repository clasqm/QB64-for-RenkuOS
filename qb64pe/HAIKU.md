# QB64 Phoenix Edition on Haiku / RenkuOS

This tree is QB64 Phoenix Edition **3.4.0**, ported to build natively on Haiku
x86_64 with Haiku's own libraries. It is built separately from the
`qb64-classic` tree in this repository and shares no code with it.

## Build

```bash
pkgman install gcc mesa_devel glu_devel openal_devel
./setup_haiku.sh
```

The result is `./qb64pe`. `make clean OS=hai` removes the build products;
`make OS=hai BUILD_QB64=y` is what the script runs.

Generated programs are built by the same Makefile, so the compiler passes
`OS=hai` for them once it has been regenerated. The pre-generated compiler in
`internal/source` still asks for `OS=lnx`, and the Makefile maps that to `OS=hai`
when the host is Haiku, so both old and new compilers produce working builds.

## Why 3.4.0 and not something newer

| Release | Graphics/windowing backend | Builds on Haiku? |
| --- | --- | --- |
| 3.0.0 – 3.4.0 | standard GLUT API + `glutMainLoop()`, bundled FreeGLUT/GLEW sources | yes, using Haiku's `libglut` |
| 3.5.0 – 4.6.0 | the same bundled FreeGLUT, but `libqb` now drives it through private entry points (`glut_presetup`, `glut_thread`, `glut_queue`, `glut_up`, `glut_get`) and no longer calls `glutMainLoop()` | no: those symbols only exist in PE's patched FreeGLUT, which is X11/Win32 only |
| 4.7.0-GLFW | GLFW 3.5.1 + GLAD | no: HaikuPorts has GLFW 3.3.7 and GLFW has no upstream Haiku platform |

## What the port changes

| Area | Change |
| --- | --- |
| Platform detection | `internal/c/libqb/include/libqb-common.h` defines `QB64_HAIKU`, `QB64_UNIX` and `QB64_GCC` for `__HAIKU__` |
| GLUT | `internal/c/parts/core/src.c` includes Haiku's `<GL/glut.h>` instead of the bundled FreeGLUT and deliberately does **not** define `CORE_FREEGLUT` |
| GLEW | no GLEW at all: Mesa's `libGL` exports the `GL_EXT` entry points, so `libqb-common.h` defines `GL_GLEXT_PROTOTYPES` and `<GL/glext.h>` declares them as plain prototypes (Haiku's `glext.h` and `glew.h` cannot be mixed, and GLEW needs `glXGetProcAddress`, which Haiku lacks). Framebuffer object support is probed with `glGetString(GL_EXTENSIONS)` |
| Build system | `Makefile` gained an `OS=hai` target (POSIX paths, `-no-pie`, no `-lX11`/`-ldl`/`-lrt`/`-lasound`, links `-lGL -lGLU -lglut -lopenal -lbe -lnetwork -lpthread -lm`) plus a host check that turns `OS=lnx` into `OS=hai` on Haiku |
| FreeGLUT core | `internal/c/parts/core/build.mk` skips the bundled FreeGLUT/GLEW on Haiku |
| OpenAL | the bundled OpenAL Soft sources are not compiled; the HaikuPorts `openal` package is linked instead (it has a native Media Kit backend) |
| Clipboard | `BClipboard` for `_CLIPBOARD`/`CLIPBOARD$` |
| Alerts | `MessageBox()` uses `BAlert`, because tinyfiledialogs needs zenity/kdialog on Unix |
| Executable directory | located with `get_next_image_info()` (Haiku has no `/proc/self/exe`) |
| Clock | `clock_gettime(CLOCK_MONOTONIC)` |
| `_OS$` | reports `[HAIKU][64BIT][LINUX]`, so `$IF LINUX` code applies to Haiku as well |
| Keyboard | Haiku's GLUT reports Return as LF (10); `GLUT_key_ascii()` normalizes it to CR (13) before modifier handling, so Enter works without holding Ctrl |
| Gamepads | `BJoystick` backend (`Gamepad_haiku.c`, compiled as C++ because `BJoystick` is a class) |
| IDE | "open file/URL" links use Haiku's `open` command |

## Deliberately unchanged

The IDE's menus, shortcut labels and key handling are exactly as upstream
shipped them in 3.4.0; this port does not carry the cosmetic menu changes that
were made to the classic tree.

## Known gaps

* **Audio**: playback goes through system OpenAL Soft. The miniaudio path
  (`_SNDNEW` streaming) compiles but has no native Haiku backend, so it will
  fall back to a null device.
* **File dialogs** (`_FILEDIALOG`) still use tinyfiledialogs, which shells out to
  zenity/kdialog. There is no Haiku-native implementation yet; the IDE's own file
  dialogs are unaffected.
* **MIDI** uses the bundled software synth, so it works, but the soundfont
  object is linked with `objcopy` exactly as on Linux.
* Nothing here has been built yet; expect the first compiler pass to turn up
  errors. Send them back and they will be fixed.
