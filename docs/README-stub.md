TODO: game title
================

**TODO:** what gamejam entry is this?  What was the theme?

**TODO:** [Official submission](SUBMISSION-LINK-HERE) + [itch.io](ITCH-IO-LINK).

**TODO:** add gameplay preview: `![gameplay](screenshots/GAMEPLAY_PREVIEW)`

**TODO:** Setting introduction: plot and goals.


Controls
========


Rules
=====


Scoring
=======


Building from source
====================

**TODO:** build instructions below assume that you used `gameWheel`.  Modify
accordingly.

Written in [Haxe](https://haxe.org/) using [heaps.io](https://heaps.io/) engine
with [gameWheel](https://github.com/jstolarek/gameWheel) as a starting point.
To compile and run the game you need a working installation of Haxe 4.x and
[Hashlink](https://hashlink.haxe.org).  Required libraries are included as
submodules in the repo.  On Linux run `./init.sh` script after checkout to
update the submodules, create a local `haxelib` sandbox, and install the
required libraries into the sandbox.  Alternatively you can do this manually by
running the commands from the `init.sh` script.

The following build targets are available:

  * SDL development build (Linux or Windows platforms via hashlink target):
    compile and run with `make devel.hl`.  Run with `make run.hl`

  * JavaScript development build (any modern web browser): compile with `make
    devel.js`, run with `make run.js` or by opening `index.html` in a web
    browser.

On Linux you can create release builds for Linux, Windows, and HTML5 by running
`make release`.  See [`RELEASE.md`](docs/RELEASE.md] for details.


Screenshots
===========

**TODO:** add some screenshots like this: `![TITLE](screenshots/SCREENSHOT.JPG)`


Known bugs
==========

**TODO:** list known bugs and problems


Credits
=======

**TODO:** list people

  * Programming:
  * Graphics:
  * Sound:
  * Writing:
