# QB64

![githubstrip](https://user-images.githubusercontent.com/10699359/109433808-1026f580-79f1-11eb-9472-2d4180dff14c.png)

QB64 is a modern extended BASIC+OpenGL language that retains QB4.5/QBasic
compatibility and compiles native binaries for Haiku (x86_64). This repository is
a RenkuOS / Haiku-only fork that offers two independent QB64 implementations side
by side:

| Folder | What it is | State |
| --- | --- | --- |
| `qb64-classic` | the original QB64 2.1 development line | the mature port: IDE, compiler and generated programs all work |
| `qb64pe` | QB64 Phoenix Edition **3.4.0** | newly ported to Haiku, first build pending |

Each tree is a complete, self-contained toolchain with its own `setup_haiku.sh`,
`internal/` and `source/`; they share no files and can be built independently.

![qb64.png](https://i.postimg.cc/SRNqQgk6/qb64.png)

## Why Phoenix Edition 3.4.0?

3.4.0 is the newest QB64-PE release whose runtime still uses the plain GLUT API
and drives its own `glutMainLoop()`. Starting with 3.5.0, PE's `libqb` calls
private entry points (`glut_presetup`, `glut_thread`, `glut_queue`, ...) that only
the project's own patched FreeGLUT provides, and its bundled FreeGLUT is X11/Win32
only. Haiku ships a GLUT 3.7 implementation (`libglut`) and has no freeglut in its
repositories, so 3.5.0 and later would need a whole new Haiku backend for that
window layer. 4.7.0 went further and replaced FreeGLUT with GLFW 3.5.1 and GLAD,
and HaikuPorts only offers GLFW 3.3.7.

So the Haiku builds use Haiku's own GLUT, which is exactly the API 3.4.0 expects.

# Installation

Both trees build natively on RenkuOS / Haiku x86_64 only.

## Haiku

Install the toolchain and the required HaikuPorts packages:

```bash
pkgman install gcc mesa_devel glu_devel openal_devel
pkgman install devel:libGLEW
```

`glew_devel` is the package name on some repository snapshots; `devel:libGLEW`
resolves to whichever package currently provides it.

Then build the tree you want:

```bash
cd qb64-classic
./setup_haiku.sh
```

```bash
cd qb64pe
./setup_haiku.sh
```

The classic tree can also be built with CMake:

```bash
cd qb64-classic
mkdir build && cd build && cmake .. && make
```

# Usage

Run the `qb64` (classic) or `qb64pe` (Phoenix Edition) executable to launch the
IDE, which you can use to edit your .BAS files. From there, hit F5 to compile and
run your code.

To generate a binary without running it, hit F11.

We have the retro IDE because it is cool. But you don't need it. You can write
QB64 programs with any text editor and compile from Terminal. If you do not
wish to use the integrated IDE and to only compile your program, you can use the
following command-line calls:

`qb64 -x yourfile.bas` (or `qb64pe -x yourfile.bas`)

`qb64 -x yourfile.bas -o outputname` (or `qb64pe ...`)

When doing this, QB64 really appreciates getting the entire pathname. This can
be done easily by dragging the .bas file into the Terminal window.

# What is different on Haiku

* Menu shortcuts are the ones each tree ships with; nothing in the keyboard
  handling was changed beyond what Haiku's GLUT needs.
* Phoenix Edition uses Haiku's `libglut`, the HaikuPorts `openal` package (which
  has a native Media Kit backend) and HaikuPorts GLEW. The FreeGLUT and GLEW
  sources bundled with PE are not compiled.
* File dialogs and alerts: PE's tinyfiledialogs shell-outs (zenity/kdialog) do
  not exist on Haiku, so message boxes use `BAlert`.
* Gamepads use `BJoystick`; the clipboard uses `BClipboard`.
* See `qb64-classic/HAIKU.md` and `qb64pe/HAIKU.md` for the porting notes.

# Credits

QB64 was created by Galleon and is maintained by the QB64 community. Phoenix
Edition is the continuation from https://github.com/QB64-Phoenix-Edition/QB64pe
and keeps its original licence (see the `COPYING.txt` and `licenses/` in each
tree).
