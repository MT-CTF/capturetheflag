CaptureTheFlag Lua API Reference
==================================
# Introduction
Capture the Flag is a Luanati(formerly Minetest) based game. The following API docs covers the various mods which make up the game. If you have any difficulty in understanding this, please read [Programming in Lua](http://www.lua.org/pil/).    
If you see a deficiency in the API, feel free to attempt to add the functionality in the engine and API, and to document it here. All mods are contained in the `/mods/` folder. If you are unsure of the implementation of the function, please search for the function in the repository. 

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

## ctf_map
#### `ctf_map.set_flag_location(pname, teamname, pos)`
* `pname` *string*: Player name
* `teamname` *string*: Team name
* `pos` *position*: Position of flag

#### `ctf_map.show_map_editor(player)`
* `player` *PlayerObj*: Player to show the editor.

#### `ctf_map.show_map_save_form(player, scroll_pos)`
* `player` *PlayerObj*: Player to show the editor.
* `scroll_pos` ???

#### `ctf_map.skybox_exists(subdir)`
* `subdir` *string*: Folder to check if skybox exists.

#### `ctf_map.load_map_meta(idx, dirname)`
* `idx` *integer*: Index of the map
* `dirname` *string*: Path to map folder.

#### `ctf_map.save_map(mapmeta)`
* `mapmeta` *MapMeta*: Map metadata to be saved on computer.

#### `ctf_map.announce_map(map)`
* `map` *MapMeta*: Map to be announced

#### `ctf_map.place_map(mapmeta, callback)`
* `mapmeta` *MapMeta*: Map to be placed.
* `callback` *Function*: Function to be executed after map is placed.

#### `ctf_map.remove_barrier(mapmeta, callback)`
* `mapmeta` *MapMeta*: Map to be removed barrier of.
* `callback` *Function*: Function to be executed after map barrier is removed.

#### `ctf_map.prepare_map_nodes(mapmeta, treasurefy_node_callback, team_chest_items, blacklisted_nodes)`
???

#### `ctf_map.getduration()`
* returns `string` representing time elapsed after map start_time.

#### `ctf_map.register_map(dirname, path_to_map)`
* `dirname` *string*: directory name
* `path_to_map` *string*: By default "/". `<path_to_map>/<dirname>`

#### `ctf_map.register_maps_dir(path_to_folder)`
* `path_to_map` *string*: By default "/". `<path_to_map>/<dirname>`

#### `ctf_map.register_map_command(match, func)`
* `match` *string*: Map command
* `func` *Function*: function to be executed.

#### `ctf_map.emerge_with_callbacks(name, pos1, pos2, callback, progress)`
* `name` *string*: Name of map.
* `pos1` *Position*: Position 1
* `pos2` *Position*: Position 2
* `callback` *Function*: Callback function
* `progress` ???

#### `ctf_map.get_pos_from_player(name, amount, donefunc)`
* `name` *string*: Player name
* `amount` ???
* `donefunc`: Function to execute after function executes.

## ctf_report
#### `ctf_report.register_on_report(func)`
* `func` *Function* function to be executed on report. The function `func` needs to have arguments of `name`, `message`.

#### `ctf_report.default_send_report(msg)`
* `msg` *string* Display message to all staff.

## ctf_player
#### `ctf_player.set_stab_slash_anim(anim_type, player, extra_time)`
* `anim_type` *string*: Animation type
* `player` *PlayerObj*: Player
* `extra_time` *integer*: Extra time for animation.

## ctf_teams
#### `ctf_teams.remove_online_player(player)`
* `player` *string|PlayerObj*: Player Name|Player

#### `ctf_teams.set(player, new_team, force)`
* `player` *string|PlayerObj*: Player Name|Player
* `new_team` *string*: New team color
* `force` *boolean*: Force allocate into new team.
* 
#### `ctf_teams.get(player)`
* `player` *string|PlayerObj*: Player Name|Player
* returns `nil|string` representing player's team.

#### `ctf_teams.default_team_allocator(player)`
* `player` *string|PlayerObj*: Player Name|Player
* returns `nil|string` representing player's team.

#### `ctf_teams.team_allocator(player)`
* `player` *string|PlayerObj*: Player Name|Player
* returns `nil|string` representing player's team.
* (just gets the team that player should be joined to, and doesnt set the team)

#### `ctf_teams.allocate_player(player, force)`
* `player` *string|PlayerObj*: Player Name|Player
* `force` *boolean*: Force allocate into new team.
*  returns `nil|string` representing player's team.

#### `ctf_teams.allocate_teams(teams)`
* `teams` *table*: Table of teams.
* (should be called at match start)

#### `ctf_teams.get_team_territory(teamname)`
* `teamname` *string*: Team name
* returns `boolean| pos1,pos2* false or positions representing the region of the team.  

#### `ctf_teams.chat_send_team(teamname, message)`
* `teamname` *string*: Team name - All players in that team will recieve the message. 
* `message` *message*: Message

#### `ctf_teams.get_connected_players()`
* returns a `table` of connected players but leaves players which arent in a team,

#### `ctf_teams.is_allowed_in_team_chest(listname, stack, player)`
* `listname` ???
* `stack` *table(ItemDef)*: Item to be put into chest. 
* `player` *PlayerObj*: Player

#### `ctf_teams.register_on_allocplayer(func)`
* `func` *Function*: function to be executed after allocating a team to player.

## ctf_rankings

#### `ctf_rankings:rankings_sorted()`
* returns `boolean`

#### `ctf_rankings:init()`
* returns `rankings()`

#### `ctf_rankings.register_on_rank_reset(func)`
* `func` *Function*: function to be executed after ranking reset. 

#### `ctf_rankings.update_league(player)`
* `player` *PlayerObj*: Player

### Rankings() object.
Depending on the database used, such as `redis` or `modstorage/default` defines common interface to handle with database. 

#### `rankings:get(pname)`
* `pname` *string*: Player name
* returns `rank_str` *string*

#### `rankings:set(pname,newrankings, erase_unset)`
* `pname` *string*: Player name
* `newrankings` *string* New rankings of player
* `erase_unset` *boolean* ???
* returns `rank_str` *string*

#### `rankings:add(pname,score)
* `pname` *string*: Player name
* `score` *number*: Score

#### `rankings:del(pname)`
* `pname` *string*: Player name

#### `rankings.top:new()`
* returns ???

#### `rankings.top:set(player,score)`
* `player` *string*: Player name
* `score` *number*: Score

#### `rankings.top:get_place(player)`
* `player` *string*: Player name
* returns `place` *integer*

#### `rankings.top:get_top(count)`
* `count` *integer*: Count of no of players.
* returns `list(string)` of players whose rank is less than `count`

## ctf_modebase

#### `ctf_modebase.bounties.claim(player, killer)`
* `player` *string*: Player name
* `killer` *string*: Killer player name
* returns `rewards` *integer* (bonus score to be given to killer)

#### `ctf_modebase.bounties.reassign()`
* reassigns the bounties.

#### `ctf_modebase.bounties.reassign_timer()`
* reassigns the timer, after which the bounties should be re-assigned.

#### `ctf_modebase.bounties.bounty_reward_func()`
* returns `table` of `{bounty_kills = 1, score = x}`

#### `ctf_modebase.bounties.get_next_bounty(team_members)`
* `team_members` *table* : Team members.
* returns *string* with playername of random team member in table.

#### `ctf_modebase.bounty_algo.kd.get_next_bounty(team_members)`
* `team_members` *table* : Team members.
* returns *table* of team members with highest kd's. 

#### `ctf_modebase.bounty_algo.kd.bounty_reward_func(pname)`
* `pname` *string*: Player bounty put over.
* returns `table` of `{bounty_kills = 1, score = x}`

#### `ctf_modebase.build_timer.start(build_time)`
* `build_time` *integer*: Build time in seconds.

#### `ctf_modebase.build_timer.finish()`
* called after build_time elapses.

#### `ctf_modebase.update_crafts(name)`
* `name` *string*: Name of mode.
* locks all crafts not supported by the mode.

#### `ctf_modebase.is_immune(player)`
* `player` *PlayerObj*: Player
* returns *boolean*

#### `ctf_modebase.give_immunity(player, respawn_timer)`
* `player` *PlayerObj*: Player
* `respawn_timer` *integer*: Amount of time to give immunity to player

#### `ctf_modebase.remove_immunity(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.remove_respawn_immunity(player)`
*  Remove immunity and return true if it's respawn immunity, return false otherwise.
* `player` *PlayerObj*: Player
* returns *boolean*

#### `ctf_modebase.update_playertags(time)`
???

#### `ctf_modebase.map_chosen(map, ...)`
* `map` *MapDef*: Map
* `...` ???

#### `ctf_modebase.map_catalog.select_map(filter, full_pool)`
???

#### `ctf_modebase.map_catalog.select_map_for_mode(mode)`
* `mode` *string*: Game mode (classic/nade_fight/classes)

#### `ctf_modebase.features.on_new_match()`
#### `ctf_modebase.features.on_match_end()`

#### `ctf_modebase.features.team_allocator(player)`
* `player` *PlayerObj*: Player
* returns the `team` *string* which player has to join.

#### `ctf_modebase.features.can_take_flag(player,teamname)`
* `player` *PlayerObj*: Player
* `teamname` *string*: Team whose flag is being taken.
* returns *boolean*

#### `ctf_modebase.features.on_flag_take(player,teamname)`
* `player` *PlayerObj*: Player
* `teamname` *string*: Team whose flag is being taken.

#### `ctf_modebase.features.on_flag_drop(player,teamnames,pteam)`
* `player` *PlayerObj*: Player
* `teamnames` *list(string)*: Team whose flag is being taken.
* `pteam` *string*: Player's team

#### `ctf_modebase.features.on_flag_capture(player,teamnames)`
* `player` *PlayerObj*: Player
* `teamnames` *list(string)*: Team whose flag is being taken.

#### `ctf_modebase.features.on_allocplayer(player, new_team)`
* `player` *PlayerObj*: Player
* `teamname` *string*: Team where player is being joined to. 

#### `ctf_modebase.features.on_leaveplayer(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.features.on_dieplayer(player,reason)`
* `player` *PlayerObj*: Player
* `reason` *string*: Reason for death.

#### `ctf_modebase.features.on_respawnplayer(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.features.get_chest_access(pname)`
* `pname` *string*: Player name

#### `ctf_modebase.features.on_punchplayer = function(player, hitter, damage, _, tool_capabilities)`
* `player` *PlayerObj*: Player
* `hitter` *PlayerObj*: Hitter
* `damage` *integer*: Damage recieved
* `_` * ???
* `tool_capabilities` ???

#### `ctf_modebase.features.on_healplayer(player,patient,amount)`
* `player` *PlayerObj*: Player(Healer)
* `patient` *PlayerObj*: Patient

#### `ctf_modebase.markers.add(pname, msg, pos, no_notify, specific_player)`
* `pname` *string*: Player name
* `msg` *string*: Message
* `pos` *Position*: Position to put marker at
* `no_notify` *boolean*: If `false`, informs teammates about placed marker in chat.
* `specific_player` *string*: Marker placed for a  specific player. 

#### `ctf_modebase.markers.remove(pname, no_notify)`
* `pname` *string*: Player name
* `no_notify` *boolean*: If `false`, informs teammates about removed marker in chat.

#### `ctf_modebase.map_chosen(map)`
* `map` *MapDef*: Map chosen to be played.

#### `ctf_modebase.start_match_after_vote()`
* Starts the next match after map vote. 

#### `ctf_modebase.start_new_match(delay)`
* `delay` *integer*: Delay of x seconds before match start. 

#### `ctf_modebase.mode_vote.start_vote()`
* starts vote, to select how matches to play. 

#### `ctf_modebase.mode_vote.end_vote()`
* ends vote, queue's a mode change. 

#### `ctf_modebase.player.save_initial_stuff_positions(player, soft)`
* `player` *PlayerObj*: Player
* `soft` ???

#### `ctf_modebase.player.give_initial_stuff(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.player.empty_inv(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.player.remove_bound_items(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.player.remove_initial_stuff(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.player.update(player)`
* `player` *PlayerObj*: Player
* this is used to update skyboxes, shadows and physics. 

#### `ctf_modebase.player.is_playing(player)`
* `player` *PlayerObj*: Player
* returns *boolean*

#### `ctf_modebase.recent_rankings.add(player,amounts,no_hud)`
* `player` *PlayerObj*: Player
* `amounts` *list(table(string,integer))*:
* `no_hud` *boolean*: If *true* then no hud will be shown. 

#### `ctf_modebase.recent_rankings.get(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.recent_rankings.on_leaveplayer(player)`
* `player` *PlayerObj*: Player

#### `ctf_modebase.recent_rankings.on_match_end()`

#### `ctf_modebase.recent_rankings.players()`
* returns `rankings_player` *table*

#### `ctf_modebase.recent_rankings.teams()`
* returns `teams` *table*

#### `ctf_modebase.prepare_respawn_delay(player)`
* `player` *PlayerObj*: Player
* prepare player for respawn and start respawn delay. 

#### `ctf_map.treasure.treasurefy_node(inv, map_treasures)`
* `inv` *InventoryTable*: Chest Inventory
* `map_treasures` *table*: Allowed map treasures. 

#### `ctf_map.treasure.treasure_from_string(str)`
* `str` *string*: String of form: `name ; min_count ; max_count ; max_stacks ; rarity ;;`

#### `ctf_map.treasure.treasure_to_string(treasures)`
* `treasures` *table*: treasures to string form. 

#### `ctf_modebase.update_wear.find_item(pinv, item)`
* `pinv` *InventoryTable*: Player inventory
* `item` `Item`: item

#### `ctf_modebase.update_wear.start_update(pname, item, step, down, finish_callback, cancel_callback)`
???

#### `ctf_modebase.update_wear.cancel_player_updates(pname)`
* `pname` *string* : Player name

#### `ctf_modebase.flag_huds.update_player(player)`
* `player` *PlayerObj* : Player
* handles team huds showing flag status.

#### ` ctf_modebase.flag_huds.track_capturer(player, time)`
* `player` *PlayerObj* : Player
* `time`  *integer*: Amount of time in seconds to track flag for. 

#### ` ctf_modebase.flag_huds.untrack_capturer(player)`
* `player` *PlayerObj* : Player

#### `ctf_modebase.drop_flags(player)`
* `player` *PlayerObj* : Player

#### `ctf_modebase.flag_on_punch(puncher, nodepos, node)`
* `puncher` *PlayerObj* : Player
* `nodepos` *Position*: Position of node. 
* `node` *NodeDef*: Node clicked on. 

#### `ctf_modebase.register_mode(name, def)`
* `name` *string*: Mode Name
* `def` *modeDef*: Definition of mode. (Check `classes` mode def for example)

#### `ctf_modebase.on_mode_end()`
* returns *boolean* on wheter the mode has ended or not.

#### `ctf_modebase.on_mode_start()`
* to be run when a new mode starts. Runs all functions that are scheduled to be called on new mode.

#### `ctf_modebase.on_new_match()`
* to be run when a new match is supposed to start. Runs all functions that are scheduled to be called on new match.

#### `ctf_modebase.on_match_start()`
* to be run when a new match starts. Runs all functions that are scheduled to be called on new match.

#### `ctf_modebase.on_match_end()`
* to be run when a match ends. Runs all functions that are scheduled to be called on match end.

#### `ctf_modebase.on_respawnplayer(player)`
* `player` *PlayerObj*: Player
* Runs all functions that are scheduled to be called when a player respawns.

#### `ctf_modebase.on_flag_rightclick(...)`
* `...` ??? 
* Defines behavior when the flag is clicked with the right mouse key.

#### `ctf_modebase.on_flag_capture(capturer, flagteams)`
* `capturer`*PlayerObj* 
* `flagteams` *list(string)* (list of the teams of the flags taken)

#### `ctf_modebase.match_mode(param)`
* ???

#### `ctf_modebase.skip_vote.start_vote()`
* Start the skipping match process. 

#### `ctf_modebase.skip_vote.end_vote()`
* End the skip match process. Appropriately skip the match or abstain based on the votes. 

#### `ctf_modebase.skip_vote.on_flag_take()`
* Increment holding flag count.

#### `ctf_modebase.skip_vote.on_flag_drop(count)`
* `count` *int*: Current flag count
* If flag count falls to zero, and skip vote has chosen match to skip, then skip the map.

#### `ctf_modebase.skip_vote.on_flag_capture(count)`
`count` *int*: Current flag count
* If flag has been captured, then remove the skip vote timer and end the match.

#### `ctf_modebase.summary.get(prev)`
* `prev` *boolean*: Whether previous rankings to be shown.
* Returns a `table` with the relevant match summary. 

#### `ctf_modebase.summary.set_winner(i)`
* `i` *int*: int

#### `ctf_modebase.summary.show_gui(name, rankings, special_rankings, rank_values, formdef)`
* `name` *string*: Player name
* `rankings` *table*: Recent rankings to show in the gui
* `rank_values` *table*: Example: `{_sort = "score", "captures" "kills"}`
* `formdef` *table*: table for customizing the formspec

#### `ctf_modebase.summary.show_gui_sorted(name, rankings, special_rankings, rank_values, formdef)`
* `name` *string*: Player name
* `rankings` *table*: Recent rankings to show in the gui
* `rank_values` *table*: Example: `{_sort = "score", "captures" "kills"}`
* `formdef` *table*: table for customizing the formspec


# Footnotes
And thats the end of the api docs. If anything is missing, or something needs to be updated, feel free to make a PR. 
Last updated on: 13 Feb 2025 (GMT)
<!--
Docs for CTF by mrtechtroid. 
Released under CC BY-SA 4.0
-->
