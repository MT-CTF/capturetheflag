Minetest mod: HUD bars
======================
Version: 1.2.1

This software uses semantic versioning, as defined by version 2.0.0 of the SemVer
standard. <http://semver.org/>


License of source code: WTFPL
-----------------------------
Author: Wuzzy (2015)
Forked from the “Better HUD” [hud] mod by BlockMen.


Using the mod:
--------------
This mod changes the HUD of Minetest. It replaces the default health and breath symbols by horizontal colored bars with text showing
the number.

Furthermore, it enables other mods to add their own custom bars to the HUD, this mod will place them accordingly.

You can create a “hudbars.conf” file to customize the positions of the health and breath bars. Take a look at “hudbars.conf.example”
to get more infos. The lines starting with “--” are comments, remove the two dashes to activate a setting. Settings which are not
set will use a default value instead.


IMPORTANT:
Keep in mind if running a server with this mod, that the custom position should be displayed correctly on every screen size!

Settings:
---------
This mod can be configured by editing minetest.conf. Currently, the following setting is recognized:

- hudbars_autohide_breath: A boolean setting, it can be either “true” or “false”. If set to “true”,
  the breath bar will be automatically hidden shortly after the breathbar has been filled up. If set
  to “false”, the breath bar will always be displayed. The default value is “true”.

- hudbars_sorting: This setting allows you to specify the “slot” positions of the HUD bars manually.

  The setting has to be specified as a comma-seperated list of key=value pairs, where a key refers to the
  identifier of a HUD bar and the value refers to the slot number of where the HUD bar should be placed.
  The slot number must be an integer greater of equal to 0. The slot positions start (slot 0) at the
  bottom (nearest to hotbar in default configuration) left side, the following slot 1 is at the right
  side, slot `2` is on the right side again, but placed over the first HUD bar (slot 0), and it goes on,
  in a zig-zag pattern.
  All HUD bars to which no sorting rule has been applied will fill in all slots which have not been occupied
  by the HUD bars specified in this setting, the slots will be filled in from the lowest slot number.
  Note that the order of those remaining HUD bars is *not* fixed, it basically just boils down on which mod
  “came” first. Don't worry, the mod will still work perfectly fine, this setting is entirely optional.

  Be careful not to use slot indices twice, or else different HUD bars will be drawn over each other!

  If this setting is not set, by default the health and breath bar are displayed at slot positions 0 and 1,
  respectively (health bar at left bottom-most positoin, breath bar right from it). All other HUD bars are
  placed automatically.

  Example value:
    breath=0, health=1
  This places the breath bar at the left side, and the health bar to the right side.

- hudbars_bar_type: Specifies the style of bars. You can select between the default progress-bar-like bars and the good old statbars
  like you know from vanilla Minetest. Note that the classic and modern statbars are still a little bit experimental.
  These values are possible:
    - progress_bar:    A horizontal progress-bar-like bar with a label, showing numerical value (current, maximum), and an icon.
                       These bars usually convey the most information. This is the default and recommended value..
    - statbar_classic: Classic statbar, like in vanilla Minetest. Made out of up to 20 half-symbols. Those bars represent the vague ratio between
                       the current value and the maximum value. 1 half-symbol stands for approximately 5% of the maximum value.
    - statbar_modern:  Like the classic statbar, but also supports background images, this kind of statbar may be considered to be more user-friendly
                       than the classic statbar. This bar type closely resembles the [hud] mod.

- hudbars_vmargin: The vertical distance between two HUD bars in pixels (default: 24)
- hudbars_tick: The number of seconds between two updates of the HUD bars. Increase this number if you have a slow server (default: 0.1)

Position settings:
With these settings you can configure the positions of the HUD bars. All settings must be specified as a number.
The pos settings are specified as a floating-point number between 0 to 1 each, the start_offset settings are
specified as whole numbers, they specify a number of pixels.
The left and right variants are used for the zig-zag mode. In the stack_up and stack_down modes, only the left variant is used for
the base position

- hudbars_pos_left_x, hudbars_pos_left_y: Screen position (x and y) of the left HUD bar in zigzag mode. 0 is left-most/top, 1 is right-most/bottom.
	Defaults: 0.5 (x) and 1 (y)
- hudbars_pos_right_x, hudbars_pos_right_y: Same as above, but for the right one.
	Defaults: 0.5 and 1.
- hudbars_start_offset_left_x, hudbars_start_offset_left_y: Offset in pixels from the basic screen position specified in hudbars_pos_left_x/hudbars_pos_left_y.
	Defaults: -175 and -86
- hudbars_start_offset_right_x, hudbars_start_offset_right_y: Same as above, but for the right one.
	Defaults: 15 and -86

API:
----
The API is used to add your own custom HUD bars.
Documentation for the API of this mod can be found in API.md.


License of textures:
--------------------
hudbars_icon_health.png - celeron55 (CC BY-SA 3.0), modified by BlockMen
hudbars_bgicon_health.png - celeron55 (CC BY-SA 3.0), modified by BlockMen
hudbars_icon_breath.png - kaeza (WTFPL), modified by BlockMen
hudbars_bar_health.png - Wuzzy (WTFPL)
hudbars_bar_breath.png - Wuzzy (WTFPL)
hudbars_bar_background.png - Wuzzy(WTFPL)

This program is free software. It comes without any warranty, to
the extent permitted by applicable law. You can redistribute it
and/or modify it under the terms of the Do What The Fuck You Want
To Public License, Version 2, as published by Sam Hocevar. See
http://sam.zoy.org/wtfpl/COPYING for more details.
