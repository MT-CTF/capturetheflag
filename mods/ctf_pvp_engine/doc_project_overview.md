# Welcome

The aim of CTF_PvP_Engine is to provide a base to any subgame which uses the
concepts of teams. Flags are a plugin mod, so it isn't CTF as such.

# Modules in CTF_PvP_Engine

## hudkit

A support library to make the HUD API nicer.
WTFPL.

## ctf

Requires hudkit. Support for chatplus.
Core framework, players, teams, diplomacy, hud and gui.

* core - adds saving, loading and settings. All modules depend on this.
* teams - add the concepts of teams and players. All modules except core depend on this.
* diplomacy - adds inter team states of war, peace and alliances.
* gui - adds the team gui on /team. Allows tabs to be registered.
* hud - adds the name of the team in the TR of the screen, and sets the color

## ctf_chat

Requires ctf. Support for chatplus.
Chat commands and chat channels.

## ctf_colors

Requires ctf. Support for 3d_armor.
Adds player colors.

* gui - settings form
* hud - team name color, player skin color, nametag color
* init - table of colors

## ctf_flag

Requires ctf and ctf_colors. Support for chatplus.
Adds flags and flag taking.

* api - flag callbacks, flag management (adding, capturing, updating), flag checking (asserts)
* flag_func - functions for flag node definitions.
* flags - flag node definitions.
* gui - flag naming GUI, flag teleport GUI.
* hud - waypoints, alerts ("Punch the enemy flag!" etc in top right)
* init - get nearest flag, overrides ctf.get_spawn(), minimum build range, pick up sound, flag capture timeout.

## ctf_protect

Adds node ownership / protection to teams.
Requires ctf_flag.

# Past/Other Mods

Please look

## ctf_turret

Adds auto-firing turrets that fire on enemies.
See git history.

## Capture the flag

more mods available in [capture the flag](http://github.com/rubenwardy/capturetheflag/).

* ctf_match - adds the concept of winning, match build time,
	and reseting the map / setting up a new game.
	Requires ctf_flag
