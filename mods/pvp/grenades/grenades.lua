local function remove_flora(pos, radius)
	local pos1 = vector.subtract(pos, radius)
	local pos2 = vector.add(pos, radius)

	for _, p in ipairs(minetest.find_nodes_in_area(pos1, pos2, "group:flora")) do
		if vector.distance(pos, p) <= radius then
			minetest.remove_node(p)
		end
	end
end

local function check_hit(pos1, pos2, obj)
	local ray = minetest.raycast(pos1, pos2, true, false)
	local hit = ray:next()

	while hit and hit.type == "node" and vector.distance(pos1, hit.under) <= 1.6 do
		hit = ray:next()
	end

	if hit and hit.type == "object" and hit.ref == obj then
		return true
	end
end

local fragdef = {
	description = "Frag grenade (Kills anyone near blast)",
	image = "grenades_frag.png",
	on_explode = function(pos, name)
		if not name or not pos then
			return
		end

		local player = minetest.get_player_by_name(name)

		local radius = 10

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

		remove_flora(pos, radius/2)

		for _, v in pairs(minetest.get_objects_inside_radius(pos, radius)) do
			if v:is_player() and v:get_hp() > 0 and v:get_properties().pointable then
				local footpos = vector.offset(v:get_pos(), 0, 0.1, 0)
				local headpos = vector.offset(v:get_pos(), 0, v:get_properties().eye_height, 0)
				local footdist = vector.distance(pos, footpos)
				local headdist = vector.distance(pos, headpos)
				local target_head = false

				if footdist >= headdist then
					target_head = true
				end

				local hit_pos1 = check_hit(pos, target_head and headpos or footpos, v)

				-- Check the closest distance, but if that fails try targeting the farther one
				if hit_pos1 or check_hit(pos, target_head and footpos or headpos, v) then
					v:punch(player, 1, {
						punch_interval = 1,
						damage_groups = {
							grenade = 1,
							fleshy = 26 - ( (radius/3) * (target_head and headdist or footdist) )
						}
					}, nil)
				end
			end
		end
	end,
}


-- fragdef.description = "Sticky Frag grenade (Sticks to surfaces)"
-- fragdef.image = "grenades_frag_sticky.png"
fragdef.on_collide = function(obj)
	return true
end
grenades.register_grenade("grenades:frag", table.copy(fragdef))
--grenades.register_grenade("grenades:frag_sticky", fragdef)

-- Smoke Grenade

local SMOKE_GRENADE_TIME = 30
grenades.register_grenade("grenades:smoke", {
	description = "Smoke grenade (Generates smoke around blast site)",
	image = "grenades_smoke_grenade.png",
	on_collide = function(obj)
		return true
	end,
	on_explode = function(pos, pname)
		local player = minetest.get_player_by_name(pname)
		if not player or not pos then return end

		local pteam = ctf_teams.get(pname)

		if pteam then
			local fpos = ctf_map.current_map.teams[pteam].flag_pos

			if not fpos then return end

			if vector.distance(pos, fpos) <= 15 then
				minetest.chat_send_player(pname, "You can't explode smoke grenades so close to your flag!")
				player:get_inventory():add_item("main", "grenades:smoke")
				return
			end
		end

		minetest.sound_play("grenades_glasslike_break", {
			pos = pos,
			gain = 1.0,
			max_hear_distance = 32,
		})

		local hiss = minetest.sound_play("grenades_hiss", {
			pos = pos,
			gain = 1.0,
			loop = true,
			max_hear_distance = 32,
		})

		minetest.after(SMOKE_GRENADE_TIME, minetest.sound_stop, hiss)

		for i = 0, 5, 1 do
			minetest.add_particlespawner({
				amount = 40,
				time = SMOKE_GRENADE_TIME + 3,
				minpos = vector.subtract(pos, 2),
				maxpos = vector.add(pos, 2),
				minvel = {x = 0, y = 2, z = 0},
				maxvel = {x = 0, y = 3, z = 0},
				minacc = {x = 1, y = 0.2, z = 1},
				maxacc = {x = 1, y = 0.2, z = 1},
				minexptime = 1,
				maxexptime = 1,
				minsize = 125,
				maxsize = 140,
				collisiondetection = false,
				collision_removal = false,
				vertical = false,
				texture = "grenades_smoke.png",
			})
		end
	end,
	particle = {
		image = "grenades_smoke.png",
		life = 1,
		size = 4,
		glow = 0,
		interval = 0.3,
	}
})

-- Flashbang Grenade

--[[ local flash_huds = {}

grenades.register_grenade("grenades:flashbang", {
	description = "Flashbang grenade (Blinds all who look at blast)",
	image = "grenades_flashbang.png",
	clock = 4,
	on_explode = function(pos)
		for _, v in ipairs(minetest.get_objects_inside_radius(pos, 20)) do
			local hit = minetest.raycast(pos, v:get_pos(), true, true):next()

			if hit and v:is_player() and v:get_hp() > 0 and not flash_huds[v:get_player_name()] and hit.type == "object" and
			hit.ref:is_player() and hit.ref:get_player_name() == v:get_player_name() then
				local playerdir = vector.round(v:get_look_dir())
				local grenadedir = vector.round(vector.direction(v:get_pos(), pos))
				local pname = v:get_player_name()

				minetest.sound_play("glasslike_break", {
					pos = pos,
					gain = 1.0,
					max_hear_distance = 32,
				})

				if math.acos(playerdir.x*grenadedir.x + playerdir.y*grenadedir.y + playerdir.z*grenadedir.z) <= math.pi/4 then
					flash_huds[pname] = {}

					for i = 0, 5, 1 do
						local key = v:hud_add({
							hud_elem_type = "image",
							position = {x = 0, y = 0},
							name = "flashbang hud "..pname,
							scale = {x = -200, y = -200},
							text = "default_cloud.png^[colorize:white:255^[opacity:"..tostring(255 - (i * 20)),
							alignment = {x = 0, y = 0},
							offset = {x = 0, y = 0}
						})

						flash_huds[pname][i+1] = key

						minetest.after(2 * i, function()
							if minetest.get_player_by_name(pname) then
								minetest.get_player_by_name(pname):hud_remove(key)

								if flash_huds[pname] then
									table.remove(flash_huds[pname], 1)
								end

								if i == 5 then
									flash_huds[pname] = nil
								end
							end
						end)
					end
				end

			end
		end
	end,
})

minetest.register_on_dieplayer(function(player)
	local name = player:get_player_name()

	if flash_huds[name] then
		for _, v in ipairs(flash_huds[name]) do
			player:hud_remove(v)
		end

		flash_huds[name] = nil
	end
end) ]]
