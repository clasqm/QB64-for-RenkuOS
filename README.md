# QB64

![githubstrip](https://user-images.githubusercontent.com/10699359/109433808-1026f580-79f1-11eb-9472-2d4180dff14c.png)

QB64 is a modern extended BASIC+OpenGL language that retains QB4.5/QBasic compatibility and compiles native binaries for Haiku (x86_64). This branch is a RenkuOS / Haiku-only fork.

[![qb64.png](https://i.postimg.cc/SRNqQgk6/qb64.png)](https://postimg.cc/qhYWjXtq)

originally forked from from [QB64Team/qb64](https://github.com/QB64Team/qb64). Yes, this is the abandoned original version, not the 
lively QB64PE fork. QB64PE demanded versions of glut etc. that Haiku/RenkuOS didn't have yet. Once this port is stable 
we will look at incorporating changes and fixes from that fork.

# Table of Contents
1. [Installation](#Installation)
    1. [Haiku](#Haiku)
2.  [Usage](#Usage)

# Installation <a name="Installation"></a>

QB64 on this branch builds natively on RenkuOS / Haiku x86_64 only

<a name="Haiku"></a>
## Haiku

Install the toolchain and the required HaikuPorts packages:

```bash
pkgman install gcc mesa_devel glu_devel glew_devel openal_devel
```

Then build the IDE and the compiler:

```bash
./setup_haiku.sh
```

or, with CMake:

```bash
mkdir build && cd build && cmake .. && make
```

<a name="Usage"></a>
# Usage

Run the QB64 executable to launch the IDE, which you can use to edit your .BAS files. From there, hit F5 to compile and run your code.

To generate a binary without running it, hit F11.

We have the retro IDE because it is cool. But you don't need it. You can write QB64 programs with any text editor and compile from Terminal.
If you do not wish to use the integrated IDE and to only compile your program, you can use the following command-line calls:

```qb64 -x yourfile.bas```

```qb64 -x yourfile.bas -o outputname```

When doing this, QB64 really appreciates getting the entire pathname. This can be doen easily by dragging the .bas file into the Terminal window.
