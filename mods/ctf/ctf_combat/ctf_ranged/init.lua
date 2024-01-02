local hud = mhud.init()
local shoot_cooldown = ctf_core.init_cooldowns()

ctf_ranged = {
	scoped = {}
}

local scoped = ctf_ranged.scoped
local scale_const = 6

minetest.register_craftitem("ctf_ranged:ammo", {
	description = "Ammo\nUsed to reload guns",
	inventory_image = "ctf_ranged_ammo.png",
})

local function process_ray(ray, user, look_dir, def)
	local hitpoint = ray:hit_object_or_node({
		node = function(ndef)
			return (ndef.walkable == true and ndef.pointable == true) or ndef.groups.liquid
		end,
		object = function(obj)
			return obj:is_player() and obj ~= user
		end
	})

	if hitpoint then
		if hitpoint.type == "node" then
			local node = minetest.get_node(hitpoint.under)
			local nodedef = minetest.registered_nodes[node.name]

			if nodedef.on_ranged_shoot or nodedef.groups.snappy or (nodedef.groups.oddly_breakable_by_hand or 0) >= 3 then
				if not minetest.is_protected(hitpoint.under, user:get_player_name()) then
					if nodedef.on_ranged_shoot then
						nodedef.on_ranged_shoot(hitpoint.under, node, user, def.type)
					else
						minetest.dig_node(hitpoint.under)
					end
				end
			else
				if nodedef.walkable and nodedef.pointable then
					minetest.add_particle({
						pos = vector.subtract(hitpoint.intersection_point, vector.multiply(look_dir, 0.04)),
						velocity = vector.new(),
						acceleration = {x=0, y=0, z=0},
						expirationtime = def.bullethole_lifetime or 3,
						size = 1,
						collisiondetection = false,
						texture = "ctf_ranged_bullethole.png",
					})

					minetest.sound_play("ctf_ranged_ricochet", {pos = hitpoint.intersection_point})
				elseif nodedef.groups.liquid then
					minetest.add_particlespawner({
						amount = 10,
						time = 0.1,
						minpos = hitpoint.intersection_point,
						maxpos = hitpoint.intersection_point,
						minvel = {x=look_dir.x * 3, y=4, z=-look_dir.z * 3},
						maxvel = {x=look_dir.x * 4, y=6, z= look_dir.z * 4},
						minacc = {x=0, y=-10, z=0},
						maxacc = {x=0, y=-13, z=0},
						minexptime = 1,
						maxexptime = 1,
						minsize = 0,
						maxsize = 0,
						collisiondetection = false,
						glow = 3,
						node = {name = nodedef.name},
					})

					if def.liquid_travel_dist then
						process_ray(rawf.bulletcast(
							def.bullet, hitpoint.intersection_point,
							vector.add(hitpoint.intersection_point, vector.multiply(look_dir, def.liquid_travel_dist)), true, false
						), user, look_dir, def)
					end
				end
			end
		elseif hitpoint.type == "object" then
			hitpoint.ref:punch(user, 1, {
				full_punch_interval = 1,
				damage_groups = {ranged = 1, [def.type] = 1, fleshy = def.damage}
			}, look_dir)
		end
	end
end

-- Can be overridden for custom behaviour
function ctf_ranged.can_use_gun(player, name)
	return true
end

--- Play ephemeral sound on the spot of a player.
-- @param user ObjectRef: The player object.
-- @param sound_name str: The name of the sound to be played.
-- @param spec? table: The SimpleSoundSpec of the sound. Some fields are overriden.
local function play_player_positional_sound(user, sound_name, spec)
	-- This function handles positional sounds that are
	-- supposed to be heared equally on both left and right channel
	-- by the user, while being heared at the position of the player
	-- by other players.
	-- Such a mechanism is mainly used on gunshot sounds,
	-- so the ephemeral flag is set.

	-- The spec table is copied as a base for the SimpleSoundSpec.
	-- If not supplied, one is created without any customizations.

	local user_name = user:get_player_name()

	-- Two copies of SimpleSoundSpec

	local non_user_spec = spec and table.copy(spec) or {}
	non_user_spec.pos = user:get_pos()
	non_user_spec.exclude_player = user_name

	local user_spec = spec and table.copy(spec) or {}
	user_spec.to_player = user_name

	minetest.sound_play(sound_name, non_user_spec, true)
	minetest.sound_play(sound_name, user_spec, true)
end

function ctf_ranged.simple_register_gun(name, def)
	minetest.register_tool(rawf.also_register_loaded_tool(name, {
		description = def.description,
		inventory_image = def.texture.."^[colorize:#F44:42",
		ammo = def.ammo or "ctf_ranged:ammo",
		rounds = def.rounds,
		_g_category = def.type,
		groups = {ranged = 1, [def.type] = 1, tier = def.tier or 1, not_in_creative_inventory = 1},
		on_use = function(itemstack, user)
			if not ctf_ranged.can_use_gun(user, name) then
				play_player_positional_sound(user, "ctf_ranged_click")
				return
			end

			local result = rawf.load_weapon(itemstack, user:get_inventory())

			local sound_name
			if result:get_name() == itemstack:get_name() then
				sound_name = "ctf_ranged_click"
			else
				sound_name = "ctf_ranged_reload"
			end

			play_player_positional_sound(user, sound_name)

			return result
		end,
	},
	function(loaded_def)
		loaded_def.description = def.description.." (Loaded)"
		loaded_def.inventory_image = def.texture
		loaded_def.inventory_overlay = def.texture_overlay
		loaded_def.wield_image = def.wield_texture or def.texture
		loaded_def.groups.not_in_creative_inventory = nil
		loaded_def.on_secondary_use = def.on_secondary_use
		loaded_def.on_use = function(itemstack, user)
			if not ctf_ranged.can_use_gun(user, name) then
				play_player_positional_sound(user, "ctf_ranged_click")
				return
			end

			if shoot_cooldown:get(user) then
				return
			end

			if def.automatic then
				if not rawf.enable_automatic(def.fire_interval, itemstack, user) then
					return
				end
			else
				shoot_cooldown:set(user, def.fire_interval)
			end

			local spawnpos, look_dir = rawf.get_bullet_start_data(user)
			local endpos = vector.add(spawnpos, vector.multiply(look_dir, def.range))
			local rays

			if type(def.bullet) == "table" then
				def.bullet.texture = "ctf_ranged_bullet.png"
			else
				def.bullet = {texture = "ctf_ranged_bullet.png"}
			end

			if not def.bullet.spread then
				rays = {rawf.bulletcast(
					def.bullet,
					spawnpos, endpos, true, true
				)}
			else
				rays = rawf.spread_bulletcast(def.bullet, spawnpos, endpos, true, true)
			end

			play_player_positional_sound(user, def.fire_sound)

			for _, ray in pairs(rays) do
				process_ray(ray, user, look_dir, def)
			end

			if def.rounds > 0 then
				return rawf.unload_weapon(itemstack)
			end
		end

		if def.rightclick_func then
			loaded_def.on_place = function(itemstack, user, pointed, ...)
				local pointed_def = false
				local node

				if pointed and pointed.under then
					node = minetest.get_node(pointed.under)
					pointed_def = minetest.registered_nodes[node.name]
				end

				if pointed_def and pointed_def.on_rightclick then
					return minetest.item_place(itemstack, user, pointed)
				else
					return def.rightclick_func(itemstack, user, pointed, ...)
				end
			end

			loaded_def.on_secondary_use = def.rightclick_func
		end
	end))
end

minetest.register_on_leaveplayer(function(player)
	scoped[player:get_player_name()] = nil
end)

function ctf_ranged.show_scope(name, item_name, fov_mult)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	scoped[name] = {
		item_name = item_name,
		wielditem = player:hud_get_flags().wielditem
	}

	hud:add(player, "ctf_ranged:scope", {
		hud_elem_type = "image",
		position = {x = 0.5, y = 0.5},
		text = "ctf_ranged_rifle_crosshair.png",
		scale = {x = scale_const, y = scale_const},
		alignment = {x = "center", y = "center"},
	})

	player:set_fov(1 / fov_mult, true)
	physics.set(name, "sniper_rifles:scoping", { speed = 0.1, jump = 0 })
	player:hud_set_flags({ wielditem = false })

end

function ctf_ranged.hide_scope(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	hud:remove(name, "ctf_ranged:scope")
	player:set_fov(0)
	physics.remove(name, "sniper_rifles:scoping")
	player:hud_set_flags({ wielditem = scoped[name].wielditem })
	scoped[name] = nil
end

ctf_ranged.simple_register_gun("ctf_ranged:pistol", {
	type = "pistol",
	description = "Pistol\nDmg: 2 | FR: 0.6s | Mag: 75",
	texture = "ctf_ranged_pistol.png",
	fire_sound = "ctf_ranged_pistol",
	rounds = 75,
	range = 75,
	damage = 2,
	automatic = true,
	fire_interval = 0.6,
	liquid_travel_dist = 2
})

ctf_ranged.simple_register_gun("ctf_ranged:rifle", {
	type = "rifle",
	description = "Rifle\nDmg: 1 | FR: 0.8s | Mag: 40",
	texture = "ctf_ranged_rifle.png",
	fire_sound = "ctf_ranged_rifle",
	rounds = 40,
	range = 150,
	damage = 4,
	automatic = true,
	fire_interval = 0.8,
	liquid_travel_dist = 4,
})

ctf_ranged.simple_register_gun("ctf_ranged:shotgun", {
	type = "shotgun",
	description = "Shotgun\nDmg: 1x28 | FR: 2s | Mag: 10",
	texture = "ctf_ranged_shotgun.png",
	fire_sound = "ctf_ranged_shotgun",
	bullet = {
		amount = 28,
		spread = 4,
	},
	rounds = 10,
	range = 24,
	damage = 1,
	fire_interval = 2,
})

ctf_ranged.simple_register_gun("ctf_ranged:smg", {
	type = "smg",
	description = "Submachinegun\nDmg: 1 | FR: 0.1s | Mag: 36",
	texture = "ctf_ranged_smgun.png",
	fire_sound = "ctf_ranged_pistol",
	bullet = {
		spread = 2,
	},
	automatic = true,
	rounds = 36,
	range = 75,
	damage = 1,
	fire_interval = 0.1,
	liquid_travel_dist = 2,
})

ctf_ranged.simple_register_gun("ctf_ranged:sniper", {
	type = "sniper",
	description = "Sniper rifle\nDmg: 12 | FR: 2s | Mag: 25",
	texture = "ctf_ranged_sniper_rifle.png",
	fire_sound = "ctf_ranged_sniper",
	rounds = 25,
	range = 300,
	damage = 12,
	fire_interval = 2,
	liquid_travel_dist = 10,
	rightclick_func = function(itemstack, user, pointed, ...)
		if scoped[user:get_player_name()] then
			ctf_ranged.hide_scope(user:get_player_name())
		else
			local item_name = itemstack:get_name()
			ctf_ranged.show_scope(user:get_player_name(), item_name, 4)
		end
	end
})

ctf_ranged.simple_register_gun("ctf_ranged:sniper_magnum", {
	type = "sniper",
	description = "Magnum sniper rifle\nDmg: 16 | FR: 2s | Mag: 20",
	texture = "ctf_ranged_sniper_rifle_magnum.png",
	fire_sound = "ctf_ranged_sniper",
	rounds = 20,
	range = 400,
	damage = 16,
	fire_interval = 2,
	liquid_travel_dist = 15,
	rightclick_func = function(itemstack, user, pointed, ...)
		if scoped[user:get_player_name()] then
			ctf_ranged.hide_scope(user:get_player_name())
		else
			local item_name = itemstack:get_name()
			ctf_ranged.show_scope(user:get_player_name(), item_name, 8)
		end
	end
})

------------------
-- Scope-check --
------------------

-- Hide scope if currently wielded item is not the same item
-- player wielded when scoping

local time = 0
minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time < 1 then
		return
	end

	time = 0
	for name, info in pairs(scoped) do
		local player = minetest.get_player_by_name(name)
		local wielded_item = player:get_wielded_item():get_name()
		if wielded_item ~= info.item_name then
			ctf_ranged.hide_scope(name)
		end
	end
end)
