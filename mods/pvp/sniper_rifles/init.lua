------------------
-- Private data --
------------------

-- Locally cache online players for better performance
local players = {}

-- Store list of players who were previously wielding a sniper rifle
local snipers = {}

-- Use timer to limit frequency of wielditem checks
local timer = 0

-----------------------
-- Wielditem monitor --
-----------------------

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 0.05 then
		return
	end

	timer = 0
	for name, player in pairs(players) do
		local sname = player:get_wielded_item():get_name()
		local prop  = player:get_properties()
		local prop_changed = false

		-- If they're wielding a sniper rifle, set zoom_fov. Otherwise, if
		-- they were previously wielding a sniper rifle, reset zoom_fov
		if sname:find("sniper_rifles:rifle_") then
			local def = shooter.registered_weapons[sname]
			if prop.zoom_fov ~= def.zoom_fov then
				prop.zoom_fov = def.zoom_fov
				prop_changed  = true
			end

			if not snipers[name] then
				snipers[name] = sname
			end
		elseif snipers[name] then
			local def = shooter.registered_weapons[snipers[name]]
			if prop.zoom_fov == def.zoom_fov then
				prop.zoom_fov = 0
				prop_changed  = true
			end
			snipers[name] = nil
		end

		if prop_changed then
			player:set_properties(prop)
		end
	end
end)

---------------
-- Callbacks --
---------------

minetest.register_on_joinplayer(function(player)
	if player then
		players[player:get_player_name()] = player
	end
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

-------------------------
-- Rifle registrations --
-------------------------

-- Basic 7.62mm rifle
shooter:register_weapon("sniper_rifles:rifle_762", {
	description = "Sniper rifle (7.62mm)",
	inventory_image = "sniper_rifles_rifle_762.png",
	rounds = 30,
	zoom_fov = 40,
	spec = {
		range     = 300,
		step      = 30,
		tool_caps = { full_punch_interval = 1.5, damage_groups = { fleshy = 12 } },
		sound     = { name = "sniper_rifles_rifle", gain = 0.8 },
		particle  = "shooter_bullet.png",
		groups    = {
			cracky = 3, snappy = 2, crumbly = 2, choppy = 2,
			fleshy = 1, oddly_breakable_by_hand = 1
		}
	}
})

-- Magnum rifle
shooter:register_weapon("sniper_rifles:rifle_magnum", {
	description = "Sniper rifle (Magnum)",
	inventory_image = "sniper_rifles_rifle_magnum.png",
	rounds = 20,
	zoom_fov = 25,
	spec = {
		range     = 400,
		step      = 30,
		tool_caps = { full_punch_interval = 2, damage_groups = { fleshy = 16 } },
		sound     = { name = "sniper_rifles_rifle", gain = 0.8 },
		particle  = "shooter_bullet.png",
		groups    = {
			cracky = 2, snappy = 1, crumbly = 1, choppy = 1,
			fleshy = 1, oddly_breakable_by_hand = 1
		}
	}
})

-- shooter API doesn't allow for setting wield scale, so define it after registration

minetest.override_item("sniper_rifles:rifle_762", {
	wield_scale = vector.new(2, 2, 1.5)
})

minetest.override_item("sniper_rifles:rifle_magnum", {
	wield_scale = vector.new(2, 2, 1.5)
})
