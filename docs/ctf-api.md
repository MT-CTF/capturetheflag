CaptureTheFlag Lua API Reference
==================================
# Introduction
Capture the Flag is a Luanati(formerly Minetest) based game. The following API docs covers the various mods which make up the game. If you have any difficulty in understanding this, please read [Programming in Lua](http://www.lua.org/pil/).    
If you see a deficiency in the API, feel free to attempt to add the functionality in the engine and API, and to document it here. All mods are contained in the `/mods/` folder. 

# List of all Mods. 
- api
  - ctf_gui 
  - ctf_settings
  - hud_events
  - physics
  - mhud
  - rawf
- mtg
  - redef
  - ctf_changes
- pvp
  - dropondie
  - grenades
- other
  - afkkick
  - chat_bg
  - crafting
  - darkness nerf
  - email
  - hpbar
  - hpbar_hud
  - lib_chatcmdbuilder
  - playertag
  - poison_water
  - random_messages
  - real suffocation
  - select item
  - skybox
  - sprint
  - throwable snow
  - wield3d
- ctf
  - ctf_api
  - ctf_chat
  - ctf_combat
  - ctf_core
  - ctf_cosmetics
  - ctf_landmine
  - ctf_map
  - ctf_modebase
  - ctf_modes
  - ctf_player
  - ctf_rankings
  - ctf_report
  - ctf_teams

# api
This folder contains a collection of mods with the main goal of providing an API

## ctf_gui
A tool for easily creating basic CTF-themed GUIs.   
This mod is depreciated. You can read the old api docs [here](https://github.com/MT-CTF/capturetheflag/blob/master/mods/apis/ctf_gui/api.md)

## ctf_settings
This mod adds a 'Settings' tab to the player's inventory.
Mods can use the ctf_settings API to add buttons/fields to the Settings tab that can be used to customize the mod's functionality per-player.

#### `ctf_settings.register(name, def)`
* `name` *string*: Name of setting to register
* `def` *table*: Setting properties, see below
```lua
ctf_settings.register("my_setting", {
	type = "bool" || "list",
	label = "Setting name/label", -- not used for list
	description = "Text in tooltip",
	list = {i1, i2, i3, i4}, -- used for list, remember to formspec escape contents
	default = "default value/index",
	on_change = function(player, new_value)
		<...>
	end
})
```

#### `ctf_settings.set(player, setting, value)`
* `player` *PlayerObj*: The player whos setting you want to set
* `settings` *string*: The name of the setting you want to set
* `value` *(bool | list index) as string*: The value you want to set, dependent on what the setting's type is

#### `ctf_settings.get(player, setting)`
* `player` *PlayerObj*: The player whos setting you want to get
* `setting` *string*: The name of the setting you want to get
- **returns** *(bool | list index) as string*: Returns the player's current setting value, the default given at setting registration, or if both are unset, an empty string: `""`

## hud_events
This mod allows for quick hud events to allow for quick popup messages. 
#### `hud_events.new(player, def)`
* `player` *PlayerObj*: The player who you want to show the event to.
* `def` *string|table*: Event properties, see below.
```lua
hud_events.new(player,"Simple HUD Event")
```
```lua
hud_events.new(player, {
	text= "HUD Event",
	channel=1    -- 1 by default
	color= "primary" -- 0x00D1FF by default.
	quick=true  -- false by default
})
```
List of all HUD Colors
```
	primary = 0x0D6EFD,
	secondary = 0x6C757D,
	success = 0x20bf5c,
	info = 0x0DCAF0,
	warning = 0xFFC107,
	danger = 0xDC3545,
	light = 0xF8F9FA,
	dark = 0x212529,
```
By default, all hud events are shown for 3 seconds, while quick ones are shown for 2 sec, and there is a gap of 0.6 seconds between each event.

## physics
A simple wrapper mod for overriding player physics. Only allows overriding of `speed`, `speed_crouch`, `jump`, `gravity`. 
#### `physics.set(name, layer, modifiers)`
* `name` *string*: Player name.
* `layer` *string*: Layer. ???
* `modifiers` *table*: A table of modifiers. Eg. `{speed=2,speed_crouch=2,jump=1,gravity=2}`
By default overrides are as follows: speed=1.1, jump = 1.1, speed_crouch = 1, gravity = 1. Any table entries missing, will take the default values. 

#### `physics.remove(name, layer)`
* `name` *string*: Player name.
* `layer` *string*: Layer. ???

## mhud
A wrapper for more easily managing Minetest HUDs. See the API reference [here](https://github.com/LoneWolfHT/mhud/blob/main/README.md)

## rawf
A ranged weapon framework for Minetest. See the API reference [here](https://github.com/LoneWolfHT/rawf/blob/main/API.md)


# mods/ctf/
TODO, below is a collection of quick notes for later

## ctf_teams
* https://modern.ircdocs.horse/formatting.html#colors-16-98

---
# mods/mtg/
TODO

---
# mods/other/
TODO

---
# mods/pvp/
TODO

---
