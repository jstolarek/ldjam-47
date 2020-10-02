gameWheel
=========

Source code comments - the `Note` convention
============================================

Comments of any significant size are not interleaved with code, but rather
placed separately in a named `Note` outside any function.  Notes provide a
high-level overview of intents and features.  Notes are referenced from relevant
places in the code with `// See Note [note_name]` comment, indicating there's a
note named `note_name` somewhere in the code (possibly in a different source
file) that gives details about this particular code fragment.  See [1, Section
6.1] for the origin of this convention.


Building
========

Required system tools:

  * `sed`, `tar`
  * Windows release: `zip` to compress the resulting folder
  * Linux native build: `clang`
  * MacOS release: `png2icns` to build icons (part of `icnsutils` package)
  * itch.io upload: [`butler`](https://fasterthanlime.itch.io/butler)

There are two main build targets: Hashlink VM/JIT (`hl`) and JavaScript (`js`).
Building is done with `make`.  Following `make` targets are available for
development:

  * `devel.hl` (default target), `devel.js` - build development version.  Builds
    are placed in `bin/` directory.
  * `run.hl`, `run.js` - launch the game, building the development version if
    necessary.

See [`RELEASE.md`](docs/RELEASE.md) for a list of `make` targets used to prepare
a release.


Gamejam submission readme stub
==============================

[`README-stub.md`](docs/README-stub.md) contains a stub of a Readme for a
gamejam submission.  Replace this `README.md` file with `README-stub.md` and
fill in all the required details.


References
==========

[1] Simon Marlow, Simon Peyton Jones, "The Glasgow Haskell Compiler", in "The
    Architecture of Open Source Applications, Volume 2"
