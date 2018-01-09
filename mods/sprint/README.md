# Sprint Mod For minetest

Allows players to sprint by holding E, by default increasing their travel speed
by 80% and their jump speed by 10%. Also adds a stamina bar that goes down when
the player sprints and goes up they're not sprinting.

This mod is compatible with the HUD bars [hudbars] mod, but does not depend on
it. In this case, a green HUD bar will be displayed, also showing a number.
If this mod is not present, a standard statbar with 0-20 “half-arrows” is shown,
which is a bit more coarse than the HUD bar version.

This mod is by rubenwardy, and is based on a mod by GunshipPenguin but heavily
rewritten to be more performant.

License: MIT (see license.txt)

## Settings

1.0 represents normal speed so 1.5 would mean that a sprinting player would
travel 50% faster than a walking player and 2.4 would mean that a sprinting
player would travel 140% faster than a walking player.

* `sprint_speed`- 1 is normal walking speed, defaults to 1.8.
* `sprint_jump` - 1 is normal jump speed, defaults to 1.1.
* `sprint_stamina` - How long the sprint lasts in seconds, defaults to 20.
* `sprint_heal_rate` - Multiply this by the stamina to get how long it takes to recharge, defaults to 0.5.
* `sprint_min` - The minimum value at which you can start sprinting, defaults to 0.5.

## Recharging when the sprint key is down

Follow the instructions in comments marked by `##number##`.
