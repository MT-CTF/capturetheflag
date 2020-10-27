# Real Suffocation [`real_suffocation`]
Version: 1.0.0

This mod adds suffocation. Suffocation is basically the same as drowning, but it
is for being stuck inside solid blocks. If you're inside a solid block, you lose
breath. If you lost your breath completely and you're still inside, you suffer
10 HP (=5 “hearts”) of damage every 2 seconds.

Specifically, suffocation is added to all blocks which:

* Are solid
* Are full cubes
* Don't already have built-in damage or drowning damage
* Are not excluded from suffocations by mods

## Info for modders
This mod will not add suffocation to all nodes with the group
`disable_suffocation=1`.

This mod adds the group `real_suffocation=1` to all nodes it has modified,
this is mostly done for informational purposes.

## License
Everything is under WTFPL.
