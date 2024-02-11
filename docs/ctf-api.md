CaptureTheFlag Lua API Reference
==================================

# Code Style
* Use tabs for indentation.

# mods/apis/
This folder contains a collection of mods with the main goal of providing an API

## ctf_settings
This mod adds a 'Settings' tab to the player's inventory.
Mods can use the ctf_settings API to add buttons/fields to the Settings tab that can be used to customize the mod's functionality per-player.

### `ctf_settings.register(name, def)`
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

### `ctf_settings.set(player, setting, value)`
* `player` *PlayerObj*: The player whos setting you want to set
* `settings` *string*: The name of the setting you want to set
* `value` *(bool | list index) as string*: The value you want to set, dependent on what the setting's type is

### `ctf_settings.get(player, setting)`
* `player` *PlayerObj*: The player whos setting you want to get
* `setting` *string*: The name of the setting you want to get
- **returns** *(bool | list index) as string*: Returns the player's current setting value, the default given at setting registration, or if both are unset, an empty string: `""`

---
# mods/ctf/
TODO

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
