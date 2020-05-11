local reloading = {}
local RELOAD_INTERVAL = 2

minetest.register_node("grenade_launcher:launcher", {
	description = "Grenade Launcher",
	mesh = "grenade_launcher_launcher.obj",
	tiles = {"grenade_launcher_launcher.png"},
	inventory_image = "grenade_launcher_launcher_inv.png",
	tool_capabilities = {
		full_punch_interval = RELOAD_INTERVAL,
		damage_groups = {fleshy = 3},
	},
	node_placement_prediction = "",
	drawtype = "mesh",
	stack_max = 1,
	on_place = function(itemstack)
		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		local name = user:get_player_name()
		local inv = user:get_inventory()

		if not reloading[name] and inv:remove_item("main", "grenades:frag"):get_count() > 0 then
			reloading[name] = true
			minetest.after(RELOAD_INTERVAL, function()
				local player = minetest.get_player_by_name(name)
				inv = player:get_inventory()

				if player then
					local list = inv:get_list("main")

					for idx, stack in ipairs(list) do
						if stack:get_name() == "grenade_launcher:launcher" then
							inv:set_stack("main", idx, "grenade_launcher:launcher_loaded")
							break
						end
					end
				end

				reloading[name] = nil
			end)
		end
	end,
})

minetest.register_node("grenade_launcher:launcher_loaded", {
	description = "Grenade Launcher",
	mesh = "grenade_launcher_launcher.obj",
	tiles = {"grenade_launcher_launcher_loaded.png"},
	inventory_image = "grenade_launcher_launcher_inv_loaded.png",
	tool_capabilities = {
		full_punch_interval = RELOAD_INTERVAL,
		damage_groups = {fleshy = 3},
	},
	node_placement_prediction = "",
	drawtype = "mesh",
	stack_max = 1,
	on_place = function(itemstack)
		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		grenades.throw_grenade("grenade_launcher:grenade", 30, user)
		itemstack:set_name("grenade_launcher:launcher")

		return itemstack
	end,
})

grenades.register_grenade("grenade_launcher:grenade", {
	description = "Grenade for the grenade launcher",
	image = "shooter_bullet.png",
	on_explode = function(pos, name)
		if not name or not pos then
			return
		end

		local player = minetest.get_player_by_name(name)

		local radius = 6

		minetest.add_particlespawner({
			amount = 20,
			time = 0.5,
			minpos = vector.subtract(pos, radius),
			maxpos = vector.add(pos, radius),
			minvel = {x = 0, y = 5, z = 0},
			maxvel = {x = 0, y = 7, z = 0},
			minacc = {x = 0, y = 1, z = 0},
			maxacc = {x = 0, y = 1, z = 0},
			minexptime = 0.3,
			maxexptime = 0.6,
			minsize = 7,
			maxsize = 10,
			collisiondetection = true,
			collision_removal = false,
			vertical = false,
			texture = "grenades_smoke.png",
		})

		minetest.add_particle({
			pos = pos,
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = 0.3,
			size = 15,
			collisiondetection = false,
			collision_removal = false,
			object_collision = false,
			vertical = false,
			texture = "grenades_boom.png",
			glow = 10
		})

		minetest.sound_play("grenades_explode", {
			pos = pos,
			gain = 1.0,
			max_hear_distance = 64,
		})

		for _, v in ipairs(minetest.get_objects_inside_radius(pos, radius)) do
			local hit = minetest.raycast(pos, v:get_pos(), true, true):next()

			if hit and v:is_player() and v:get_hp() > 0 and hit.type == "object" and hit.ref:is_player() and
			hit.ref:get_player_name() == v:get_player_name() then
				v:punch(player, 2, {damage_groups = {grenade = 1, fleshy = 90 * 0.707106 ^ vector.distance(pos, v:get_pos())}}, nil)
			end
		end
	end,
	on_collide = function()
		return true
	end,
	clock = 5,
	particle = { -- Adds particles in the grenade's trail
		image = "grenades_boom.png", -- The particle's image
		life = 0.5,
		size = 5,
		glow = 10,
		interval = 0.1,
	}
})
