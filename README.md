# QB64

![githubstrip](https://user-images.githubusercontent.com/10699359/109433808-1026f580-79f1-11eb-9472-2d4180dff14c.png)

QB64 is a modern extended BASIC+OpenGL language that retains QB4.5/QBasic compatibility and compiles native binaries for Haiku (x86_64). This branch is a Haiku-only fork.

# Table of Contents
1. [Installation](#Installation)
    1. [Haiku](#Haiku)
2.  [Usage](#Usage)
3.  [Additional Info](#Additional_Info)

# Installation <a name="Installation"></a>

QB64 on this branch builds natively on Haiku x86_64 only; there are no prebuilt
packages, build from source as described below.

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

Additionally, if you do not wish to use the integrated IDE and to only compile your program, you can use the following command-line calls:

```qb64 -c yourfile.bas```

```qb64 -c yourfile.bas -o outputname.exe```

Replacing `-c` with `-x` will compile without opening a separate compiler window.


<a name="Additional_Info"></a>
# Additional Information

More about QB64 at our wiki: https://wiki.qb64.org

We have a community forum at: https://forum.qb64.org

We tweet from [@QB64Team](https://twitter.com/QB64team)

Find us on Discord: https://discord.qb64.org
