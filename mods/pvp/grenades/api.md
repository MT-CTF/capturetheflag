# Grenades API

Please suggest new features here: https://forum.minetest.net/viewtopic.php?f=9&t=21466

## API

```lua
grenades.register_grenade("name", { -- Name of the grenade (Like 'smoke' or 'flashbang')
	description = "", -- A short description of the grenade.
	image = "", -- The name of the grenade's texture
	collide_with_objects = false, -- (Default: false) Controls whether the grenade collides with objects. Grenade will never collide with thrower regardless of this setting
	throw_cooldown = 0, -- How often player can throw grenades, in seconds
	on_explode = function(def, pos, name)
		-- This function is called when the grenade 'explodes'
		-- <def> grenade object definition
		-- <pos> the place the grenade 'exploded' at
		-- <name> the name of the player that threw the grenade
	end,
	on_collide = function(def, obj, name, moveresult)
		-- This function is called when the grenade collides with a surface
		-- <def> grenade object definition
		-- <obj> the grenade object
		-- <name> the name of the player that threw the grenade
		-- return true to cause grenade explosion
		-- return "stop" to stop the grenade from moving
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
