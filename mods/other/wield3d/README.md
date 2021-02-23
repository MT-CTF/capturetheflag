[mod] 3d wielded items [wield3d]
================================

Mod Version: 0.5.1

Minetest Version: 5.0.0 or later

Decription: Visible 3d wielded items for Minetest

Makes hand wielded items visible to other players.

By default the wielded object is updated at one second intervals,
you can override this by adding `wield3d_update_time = 1` (seconds)
to your minetest.conf

Servers can also control how often to verify the wield item of each
individual player by setting `wield3d_verify_time = 10` (seconds)

The default wielditem scale can now be specified by including `wield3d_scale = 0.25`


### Known Issues

Items occasionally disappear when viewing in 3rd person. This is a minetest engine bug and not the fault of the mod, turning 3rd person off then back on restores the view.

Wield item switches direction at certain animation key-frames. I have yet to identify the true cause of this issue but a specially adapted version of the player model can be found [here](https://github.com/stujones11/minetest-models/tree/master/character/sam_viewer) that attempts to work around the problem.
