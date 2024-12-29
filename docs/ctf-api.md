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

# mtg
This folder contains the Minetest Game, along with redefinitions and overrides for the CTF Game. This folder doesnt expose any new APIs on its own. Please follow the Minetest Game API Reference for the same [here](https://github.com/minetest/minetest_game/blob/master/game_api.txt). 

# pvp
This folder contains parts of game mechanics involving pvp and combat. 

## dropondie
This mod drops all items on the ground, once a player dies. It is automatically invoked on a player's death or if a player leaves the game. 

### `dropondie.drop_all(player)`
* `player` *PlayerObj*: The player you want to drop all items of.


## grenades
Adds an API that allows for easily making grenades. 

### `grenades.register_grenade(...)`
```lua
grenades.register_grenade("name", { -- Name of the grenade (Like 'smoke' or 'flashbang')
	description = "", -- A short description of the grenade.
	image = "", -- The name of the grenade's texture
	collide_with_objects = false, -- (Default: false) Controls whether the grenade collides with objects. Grenade will never collide with thrower regardless of this setting
	throw_cooldown = 0, -- How often player can throw grenades, in seconds
	on_explode = function(def, obj, pos, name)
		-- This function is called when the grenade 'explodes'
		-- <def> grenade object definition
		-- <obj> the grenade object
		-- <pos> the place the grenade 'exploded' at
		-- <name> the name of the player that threw the grenade
	end,
	on_collide = function(def, obj, name, moveresult)
		-- This function is called when the grenade collides with a surface
		-- <def> grenade object definition
		-- <obj> the grenade object
		-- <name> the name of the player that threw the grenade
		-- <moveresult> table with collision info
		-- return true to cause grenade explosion
		-- return false to stop the grenade from moving
	end,
	clock = 3, -- Optional, controls how long until grenade detonates. Default is 3
	particle = { -- Adds particles in the grenade's trail
		image = "grenades_smoke.png", -- The particle's image
		life = 1, -- How long (seconds) it takes for the particle to disappear
		size = 4, -- Size of the particle
		glow = 0, -- Brightens the texture in darkness
		interval = 5, -- How long it takes before a particle can be added
	}
})
```

# others
This folder contains a collection of lot of small mods, adding smaller functionalities and objects to game. 

## afkkick
This mod kicks players after they are Afk for an amount of time. By default, players are kicked after five minutes, although this can be configured. No API's are exposed by this mod. 

## chat_bg
This mod changes the default chat background. No API's are exposed by this mod. 

## crafting
This mod adds semi-realistic crafting with unlockable recipes to Minetest, and removes the craft grid. It aims to make crafting less of a learning curve by making it as easy as clicking a button, and also by hiding recipes that the player has not learned about yet.  Please refer to API Docs [here](https://github.com/rubenwardy/crafting)

## darkness_nerf
This mods fixes darkness, by providing a minimum glow of 3 to players, and 8 to all entities of __builtin:item. No API's are exposed by this mod. 

## email
This mod allows players to email each other. No API's are exposed by this mod. 

## hp_bar & hpbar_hud
This mod shows an HP bar over the players head. 

### `hpbar.set_icon(player, texture)`
* `player` *PlayerObj*: Player to be shown over.
* `texture` *texture*: Texture to be shown beside the HP Bar.

### lib_chatcmdbuilder
This mod allows to easily create complex chat commands with no pattern matching. The API documentation is [here](https://github.com/rubenwardy/ChatCmdBuilder/blob/master/README.md)

## playertag
This mod hides the existing tags, and adds entity based tags that are only as visible as the player.
#### `playertag.set(player, type, color, extra)`
* `player` *PlayerObj*: Player the nametag will be associated with.
* `type` *integer*: By default set it as `playertag.TYPE_ENTITY`
* `color` *Color*: The color of the text.
* `extras` *table*: (Optional) field. 
* returns a table consisting of lua entities, `{entity:, nametag_entity:, symbol_entity:}`

#### `playertag.get(player)`
* `player` *PlayerObj*: Player the nametag will be associated with.
* returns a table consisting of lua entities, `{entity:, nametag_entity:, symbol_entity:}`
#### `playertag.get_all()`
* returns the entire players table. 

## poison_water
This mod adds posionous water to the game. Poisonous water is a liquid that causes damage to entities standing in it. No API's are exposed by this mod.

## random_messages
This mod sends random messages from a list of messages, providing insights and tips. No API's are exposed by this mod.

## real_suffocation
This mod adds suffocation. Suffocation is basically the same as drowning, but it is for being stuck inside solid blocks. No API's are exposed by this mod.

## select_item
This mod provides a simple dialog for players to select an item from. The API Reference is [here](https://github.com/MT-CTF/capturetheflag/blob/master/mods/other/select_item/API.md)

## skybox
Provides a basic API for modifying a player sky box in a coherent fashion.
#### `skybox.clear(player)`
* Reverts the player skybox setting to the default.
* `player` *PlayerObj*: Player the skybox will be shown to.

#### `skybox.set(player, number)`
* Sets the skybox to the `number` in the list of current skyboxes.
* `player` *PlayerObj*: Player the skybox will be shown to.
* `number` *number*: Choose the skybox from the list of skyboxes. 

#### `skybox.restore(player)`
* Reverts the player skybox to the last `skybox.set()` value.
* Other skybox mods can properly restore the player's custom skybox.
* `player` *PlayerObj*: Player the skybox will be reverted for.

#### `skybox.add(skyboxdef)`
* Add a new skybox with skyboxdef to the list of available skyboxes.
* `skyboxdef` *SkyBoxDef* : New Skybox definition. 
```
skyboxdef = {
	[1] -- Base name of texture. The 6 textures you need to
	    -- provide need to start with this value, and then
	    -- have "Up", "Down", "Front", "Back", "Left" and
	    -- "Right", Followed by ".jpg" as the file name.
	[2] -- Sky color (colorstring)
	[3] -- Day/Night ratio value (float - [0.0, 1.0])
```
Example SkyboxDef
```lua
    {"DarkStormy", "#1f2226", 0.5, { density = 0.5, color = "#aaaaaae0", ambient = "#000000",
    	height = 64, thickness = 32, speed = {x = 6, y = -6},}},
```
#### `skybox.get_skies()`
* Get a list of availiable skyboxes

## sprint
This mod, allows the player to sprint by either double tapping w or pressing e.
No API's are exposed by this mod. 

## throwable_snow
This mod, allows snow balls to be thrown at other players as projectiles. 
#### `throwable_snow.on_hit_player(thrower, player)`
* `thrower` *PlayerObj*: Player who threw the snow. 
*  `player` *PlayerObj*: Player on whom it hit.
Override this function, if you want to change what happens on snow hit.  

## wield3d
This mod makes hand wielded items visible to other players. No API's are exposed by this mod. 

# ctf
The main engine of Capture The Flag game. The following folder consists of the collection of mods, which powers the entire game. 

## ctf_api
This mod registers the functions to be executed when certain key events happen. The following functions exist, all of which take a `func` *Function* as its parameter. 

1. `ctf_api.registered_on_mode_start(func)`
2. `ctf_api.registered_on_new_match(func)`
3. `ctf_api.registered_on_match_start(func)`
4. `ctf_api.registered_on_match_end(func)` 
5. `ctf_api.registered_on_respawnplayer(func)` - Requires a return type of *PlayerObj*
6. `ctf_api.registered_on_flag_take(func)` - Requires a return type of  a tuple having `taker`*PlayerObj* and `flag_team` *string* 
7. `ctf_api.registered_on_flag_capture(func)` - Requires a return type of  a tuple having `capturer`*PlayerObj* and `flagteams` *list(string)* (list of the teams of the flags taken) 

## ctf_chat
This mod overrides the build in chat commands, and introduces a few new chat commands. No API's are exposed by this mod. 

## ctf_combat
This modpack consists of multiple mods. 
### ctf_combat_mode
#### `ctf_combat_mode.add_hitter(player, hitter, weapon_image, time)`
* `player` *PlayerObj*: Player who was killed. 
* `hitter` *PlayerObj*: Player killed the `player`
* `weapon_image` *string*: Path to weapon_image.
* `time`: *number*: Amount of time(in sec) to show for. 
#### `ctf_combat_mode.add_healer(player, healer, time)`
* `player` *PlayerObj*: Player who was healed.. 
* `healer` *PlayerObj*: Player who healed the `player`
* `time`: *number*: Amount of time(in sec) to show for. 
#### `ctf_combat_mode.get_last_hitter(player)`
* `player` *PlayerObj*: Player.
* returns a tuple of `last_hitter` *PlayerObj*, and `weapon_image` *string*
#### `ctf_combat_mode.get_other_hitters(player, last_hitter)`
* `player` *PlayerObj*: Player. 
* `last_hitter` *PlayerObj*: Player who hit the `player` last.
* returns a table/list of *players* *list(PlayerObj)* 
#### `ctf_combat_mode.get_healers(player)`
* `player` *PlayerObj*: Player.
* returns a table/list of *healers* *list(PlayerObj)* 
#### `ctf_combat_mode.is_only_hitter(player, hitter)`
* `player` *PlayerObj*: Player who was killed. 
* `hitter` *PlayerObj*: Player killed the `player`
* returns *boolean*
#### `ctf_combat_mode.set_kill_time(player, time)`
* `player` *PlayerObj*: Player
* `time` *integer*: Time. ???
#### `ctf_combat_mode.in_combat(player)`
* `player` *PlayerObj*: Player
* returns *boolean*
#### `ctf_combat_mode.end_combat(player)`
* `player` *PlayerObj*: Player

### ctf_healing
#### `ctf_healing.register_on_heal(func, load_first)`
* `func` *Function*: function to execute on healing.
* `load_first` *boolean*: true if function has to be loaded first, before all other functions.
#### `ctf_healing.register_bandage(name, def)`
* `name` *string*: Item name of the bandage.
* `def` *ItemDef*: Item definition. (Needed: `description`, `inventory_image`, `inventory_overlay`, `wield_image`)

### ctf_kill_list
#### `ctf_kill_list.show_to_player(player)`
* `player` *PlayerObj*: Player
* returns `boolean`

#### `ctf_kill_list.add(killer, victim, weapon_image, comment)`
* `killer` *PlayerObj*: Player who killed. 
* `victim` *PlayerObj*: Player killed by `killer`
* `weapon_image` *string*: Path to image of weapon used to kill.
* `comment` *string*: comment. (such as "Combat Log")

### ctf_melee
#### `ctf_melee.simple_register_sword(name, def)`
* `name` *string*: Item name of the sword.
* `def` *ItemDef*: Item definition. (Needed: `description`, `inventory_image`, `inventory_overlay`, `wield_image`, `full_punch_interval`, `damage_groups` )

#### `ctf_melee.register_sword(name, def)`
* `name` *string*: Item name of the sword.
* `def` *ItemDef*: Item definition. (Needed: `description`, `inventory_image`, `inventory_overlay`, `wield_image`, `full_punch_interval`, `damage_groups`,`tool_capabilities`,`damage_groups` )
* ??? Difference between the two?

### ctf_ranged
#### `ctf_ranged.can_use_gun(player, name)`
* `player` *PlayerObj*: Player
* `name` *string*: Player name
* returns *boolean*
* can be overriden for custom behavior. 

#### `ctf_ranged.simple_register_gun(name, def)`
* `name` *string*: Item name of the gun.
* `def` *ItemDef*: Item definition. (Needed: `description`, `texture`, `rounds`, `type`, `inventory_image`, `inventory_overlay`, `wield_image`, `full_punch_interval`, `damage_groups`, `rightclick_func` )

#### `ctf_ranged.show_scope(name, item_name, fov_mult)`
* `name` *string*: Player name
* `item_name` *string*: Item name
* `fov_mult` *integer*: FOV Multiplier.

#### `ctf_ranged.hide_scope(name)`
* `name` *string*: Player name

## ctf_core
#### `ctf_core.init_cooldowns()`
* returns a table of `players`(table) and functions `set`, `get`.

#### `ctf_core.get_players_inside_radius(pos,radius,teamless)`
* `pos` *Position*: position.
* `radius` *integer*: Radius to check from the position.
* `teamless` *boolean*: If true then returns the players in your team, and if `false` gives an empty table.

#### ` ctf_core.register_on_formspec_input(formname, func)`
???

#### `HumanReadable(input)`
* `input` *any*: Converts any input into proper readable string format.

#### `RunCallbacks(funclist,...)`
???

#### `ctf_core.pos_inside(pos, pos1, pos2)`
* `pos` *position*: Position to check
* `pos1` *position*: One corner to check in
* `pos2` *position*: Other corner
* returns *boolean*

#### `ctf_core.register_chatcommand_alias(name, alias, def)`
* `name` *string*: Original command.
* `alias` *string*: Alias name for command
* `def` *FuncDef*: Command Definition.

#### `ctf_core.file_exists(path)`
* `path` *string*: Path to file
* returns *boolean*

#### `ctf_core.to_number(s)`
* `number` *any*: data to be converted to number.

#### `ctf_core.error(area, msg)`
* `area` *string*: Category where error occured.
* `msg` *string*: Error message

#### `ctf_core.log(area, msg)`
* `area` *string*: Category where log originated.
* `msg` *string*: Log message

#### `ctf_core.action(area, msg)`
* `area` *string*: Category where action occured.
* `msg` *string*: Action message

#### `ctf_core.warning(area, msg)`
* `area` *string*: Category where warning originated.
* `msg` *string*: Warning message

#### `ctf_core.include_files(...)`
* `...` *multiple_params*: List of files to be included/ executed along with the `init.lua`. Runs `dofile` on the same. For example,
```lua
ctf_core.include_files(
	"helpers.lua",
	"privileges.lua",
	"cooldowns.lua"
)
```
## ctf_cosmetics
#### `ctf_cosmetics.get_colored_skin(player, color)`
* `player` *PlayerObj*: Player
* `color` *string*: Color of the skin. (Default: white)

#### `ctf_cosmetics.get_skin(player)`
* `player` *PlayerObj*: Player

#### `ctf_cosmetics.get_clothing_texture(player, clothing)`
* `player` *PlayerObj*: Player
* `clothing` *string*: Type of clothing

#### `ctf_cosmetics.set_extra_clothing(player, extra_clothing)`
* `player` *PlayerObj*: Player
* `extra_clothing` ???

#### `ctf_cosmetics.get_extra_clothing(player)`
* `player` *PlayerObj*: Player

## ctf_landmine
No API's exposed in this mod. 




## ctf_teams
* https://modern.ircdocs.horse/formatting.html#colors-16-98


<!--
API Docs for CTF by mrtechtroid. 
Released under CC BY-SA 4.0
-->
