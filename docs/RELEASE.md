Preparing a release
===================

**IMPORTANT** Before making an official release customise game name, version,
and itch.io user name (optionally) at the top of `Makefile`.

`dist/` directory contains native libraries distributed with the release.  In
particular, it contains Hashlink 1.11.0 `*.hdll` files.  Make sure that you have
the same Hashlink version on your system.  All extra that files should be added
to the prepared release archives (README, etc.) should be placed in respective
subdirectories inside `dist/` directory.

The following `make` targets are available for building, packaging, and
distributing releases:

  * `release` - create release versions for HTML5, Windows, Linux, and Mac
    platforms.  Releases are placed in subdirectories of `release/` directory,
    and additionally compressed into `zip` or `tar.gz` archives.  Archives can
    be used for manual upload to [itch.io](https://itch.io).  The major
    difference between development and release builds is that the former
    contains various debugging facilities (logging, speed manipulation,
    single-frame advance, assertions, etc.).  There shouldn't really be any
    performance differences between the two types of build.

  * `upload` - upload release builds to [itch.io](https://itch.io) using
    [`butler`](https://fasterthanlime.itch.io/butler).  Rather than uploading
    compressed archives, it uploads the contents of subdirectories inside
    `release/`, allowing to save bandwidth (only changed files are uploaded).
    Make sure to run `butler login` before uploading for the first time.

In addition there are two targets for making native Linux builds:

   * `linux-native` - builds and packages a native Linux x86_64 executable,
     requires a C compiler (`clang` by default).

   * `arm-native` - packages a native Raspberry Pi 4 (ARM architecture) build.
     The compilation from C to native executable has to be done on an RPi4 - see
     below.  ARM build can be uploaded to itch.io with `make upload-arm`.


MacOS release customization
===========================

You can customize the icons by modifying the contents of `dist/icons` directory.
Note that changing these icon only affects the MacOS package and not the Windows
executable.

Additionally, you might wish to change the `CFBundleIdentifier` in
`dist/osx/Contents/Info.plist`:

```
<key>CFBundleIdentifier</key>
<string>org.game.GAME</string>
```

`GAME` is replaced automatically with a value you supplied in the `Makefile`.
You might additionally wish to change `game` to `<your name>`.


Native Linux build
==================

The `make` recipe silently assumes that `hl.h`, `hlc.h`, and `hlc_main.c` are
located where compiled can find them, e.g. `/usr/local/include`.  If not, you
need to modify the command line of `clang` in the `Makefile` to point to
location of these files inside Hashlink sources with `-I path/to/hashlink/src`.

Note that the executable is linked dynamically, which means it should be
distributed with all the required `*.so` files and launched using
`LD_LIBRARY_PATH=.`.  This is all handled by prepared scripts.  See the contents
of `dist/x86_64` directory for details on which `*.so` and `.hdll` files are
required by the executable.


Raspberry Pi 4 (ARM)
====================

It is also possible to build a native ARM release on a Raspberry Pi 4.
Currently the `Makefile` manages only the packaging part - you still need to
upload the C sources and `*.hdll` libraries to the Pi, run the build manually,
and copy the resulting executable to `dist/armv7l/bin/hl`.  Also, there are
several caveats related to building on Pi.

Firstly, Hashlink does not work on ARM processors (see
[hashlink#185](https://github.com/HaxeFoundation/hashlink/issues/185)).  This
means you have to compile via Hashlink/C target on a Linux machine to obtain C
sources.  Despite Hashlink VM being incompatible with ARM architecture you still
need the `*.hdll` and `libhl.so` libraries to pass to `clang` when building.
You can use the files provided in `dist/armv7l/bin` directory.  If you want to
build these files yourself you need to get the Hashlink sources on the Pi,
install all the dependencies required to build Hashlink, and build the libraries
with `make libs`.  That however leads to compilation errors that you need to
fix:

  1. `Makefile` defines some build options that are incompatible with ARM
     architecture: `-msse2` and `-mfpmath=sse` (SSE is x86 specific so it isn't
     recognised on ARM) and `-m32`.  Edit the `Makefile` to remove these options
     (`-m32` hides as `-m${MARCH}` in the `Makefile`).

  2. Compilation is likely to fail in `src/std/debug.c` due to
     `user_regs_struct` not being defined on ARM kernels.  Solution: put the
     whole body of a function `get_reg` between `#if false ... #endif` pragmas
     so that the body of the function contains only `return NULL`.

These steps should allow to compile libraries and obtain `libhl.so` and all the
`*.hdll` files for the ARM architecture.

Secondly, OpenGL can be a problem on the Raspberry Pi 4.  The hardware drivers
for Raspberry Pi 4 only support OpenGL 2.x, which is too low for Hashlink.  In
order to run the compiled application an RPi4 needs to use the MESA software
driver, which provides support for OpenGL 3.x.  GL driver can be switched with
`raspi-config` tool.  This information must be communicated to your users.

Finally, similarly to Linux build, the executable needs to be distributed with
all the required `*.so` and `*.hdll` files (in particular `libhl.so`, which the
user is almost certain not to have) and run with `LD_LIBRARY_PATH=.`.  Moreover,
the linker must be shown path to `libhl.so` with the `-L` option, and the
compiler needs to know the location of `hl.h`, `hlc.h`, and `hlc_main.c` files
so assuming that `libhl.so` and all the `*.hdll` files are in the same directory
as source the compiler invocation will look like this:

```
clang -O3 -o gameStub -std=c17 -I . -I /path/to/hashlink/src main.c *.hdll -L . -lhl -lSDL2 -lopenal -lm -lGL
```

Once you place the resulting executable in `dist/armv7l/bin` and rename it to
`hl`, the `Makefile` will take care of the packaging and `make upload-arm` will
upload the build to itch.io.
