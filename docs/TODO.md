gameWheel high-level ideas and TODOs
====================================

  * Add animation end callbacks?

  * Better cooldown updates. At the moment cooldowns are declared per-class and
    each class that has a cooldown field needs to take care of updating it.

  * mouse support: 82a62004726ff829716b6879c56efa55391ab82c

  * Entity and Boot disposal: see how this is done in Just a Stroll

  * Camera: heaps now has its own h2d.Camera.  I need to rethink whether I can
    re-use that instead of might custom camera.  See [relevant heaps
    PR](https://github.com/HeapsIO/heaps/pull/698)

  * Create sfx library

  * move from OGMO to CastleDB?

  * if not above, then implement entity support for OGMO?

  * add tweenies

  * Support different camera focuses?

  * implememnt per-process time manipulation
    - use per-instance utmod (now tmod)
    - make sure tmod is handled correctly by child processes
    - make sure that cooldowns handle time manipulation correctly since this
      wasn't really tested
    - also consider equiping each process with a cooldown object

  * Consider adding onUpdate callbacks to processes.  This would allow to
    dynamically set things happening during an update.

  * Add Color support

  * setup travis, use utest as example

  * Current bnt fonts generated from a program are blurry.  They are ok for
    placeholders, but I need proper pixel fonts for the final game.

  * add OGG support on JS target, use stb_ogg_sound library.  Note: this looks
    complicated.  For now it is easier to enable mp3 support in Heaps or have
    two separate music files depending on the target

  * display engine.drawCalls as part of debugging overlay
