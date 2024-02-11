
local function remove_flora(pos, radius)
	local pos1 = vector.subtract(pos, radius)
	local pos2 = vector.add(pos, radius)

	for _, p in ipairs(minetest.find_nodes_in_area(pos1, pos2, {
		"group:flora", "group:mushroom", "default:snow", "group:grenade_breakable"
	})) do
		if vector.distance(pos, p) <= radius then
			minetest.remove_node(p)
		end
	end
end

local function check_hit(pos1, pos2, obj)
	local ray = minetest.raycast(pos1, pos2, true, false)
	local hit = ray:next()

	-- Skip over non-normal nodes like ladders, water, doors, glass, leaves, etc
	-- Also skip over all objects that aren't the target
	-- Any collisions within a 1 node distance from the target don't stop the grenade
	while hit and (
		(
		 hit.type == "node"
		 and
		 (
			hit.intersection_point:distance(pos2) <= 1
			or
			not minetest.registered_nodes[minetest.get_node(hit.under).name].walkable
		 )
		)
		or
		(
		 hit.type == "object" and hit.ref ~= obj
		)
	) do
		hit = ray:next()
	end

	if hit and hit.type == "object" and hit.ref == obj then
		return true
	end
end

local fragdef = {
	description = "Frag grenade (Kills anyone near blast)",
	image = "grenades_frag.png",
	explode_radius = 10,
	explode_damage = 26,
	on_collide = function()
		return true
	end,
	on_explode = function(def, obj, pos, name)
		if not name or not pos then return end

		local player = minetest.get_player_by_name(name)
		if not player then return end


		local radius = def.explode_radius

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
							fleshy = def.explode_damage - ( (radius/3) * (target_head and headdist or footdist) )
						}
					}, nil)
				end
			end
		end
	end,
}

grenades.register_grenade("grenades:frag", fragdef)

local fragdef_sticky = table.copy(fragdef)
fragdef_sticky.description = "Sticky Frag grenade (Sticks to surfaces)"
fragdef_sticky.image = "grenades_frag_sticky.png"
fragdef_sticky.on_collide = function()
	return
end
grenades.register_grenade("grenades:frag_sticky", fragdef_sticky)

-- Smoke Grenade

local sounds = {}
local SMOKE_GRENADE_TIME = 30

local register_smoke_grenade = function(name, description, image, damage)
	grenades.register_grenade("grenades:"..name, {
		description = description,
		image = image,
		on_collide = function()
			return true
		end,
		on_explode = function(def, obj, pos, pname)
			local player = minetest.get_player_by_name(pname)
			if not player or not pos then return end

			local pteam = ctf_teams.get(pname)
			local duration_multiplier = 1
			-- it gets multiplied with the default duration

			if pteam then
				for flagteam, team in pairs(ctf_map.current_map.teams) do
					if not ctf_modebase.flag_captured[flagteam] and team.flag_pos then
						local distance_from_flag = vector.distance(pos, team.flag_pos)
						if distance_from_flag <= 15 and (damage or pteam == flagteam) then
							minetest.chat_send_player(pname, "You can't explode smoke grenades so close to a flag!")
							if player:get_hp() <= 0 then
								-- Drop the nade at its explode point if the thrower is dead
								-- Fixes https://github.com/MT-CTF/capturetheflag/issues/1160
								minetest.add_item(pos, ItemStack("grenades:"..name))
							else
								-- Add the nade back into the thrower's inventory
								player:get_inventory():add_item("main", "grenades:"..name)
							end
							return
						elseif damage and distance_from_flag <= 26 then
							duration_multiplier = 0.5
						end
					end
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
			sounds[hiss] = true
			local stop = false
			if damage then
				local function damage_fn()
					local thrower = minetest.get_player_by_name(pname)

					if thrower then
						for _, target in pairs(minetest.get_connected_players()) do
							if vector.distance(target:get_pos(), pos) <= 6 then
								local dname = target:get_player_name()
								local dteam = ctf_teams.get(dname)
								if dname ~= pname and dteam ~= pteam then
									target:punch(thrower, 10, {
										damage_groups = {
											fleshy = 1,
											poison_grenade = 1,
										}
									})
								end
							end
						end
					end

					if not stop then
						minetest.after(1, damage_fn)
					end
				end
				damage_fn()
			end

			minetest.after(SMOKE_GRENADE_TIME * duration_multiplier, function()
				sounds[hiss] = nil
				minetest.sound_stop(hiss)
				stop = true
			end)

			local p = "grenades_smoke.png^["
			local particletexture
			if pteam and damage then
				particletexture = p .. "colorize:" .. ctf_teams.team[pteam].color .. ":76^[noalpha"
			else
				particletexture = p .. "noalpha"
			end

			for i = 0, 5, 1 do
				minetest.add_particlespawner({
					amount = 40,
					time = (SMOKE_GRENADE_TIME * duration_multiplier) + (damage and 1 or 3),
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
					texture = particletexture,
				})
			end
		end,
		particle = {
			image = "grenades_smoke.png".. (damage and "^[multiply:#00ff00" or ""),
			life = 1,
			size = 4,
			glow = 0,
			interval = 0.3,
		}
	})
end

register_smoke_grenade(
	"smoke",
	"Smoke grenade (Generates smoke around blast site)",
	"grenades_smoke_grenade.png",
	false
)
register_smoke_grenade(
	"poison",
	"Poison grenade (Generates poisonous smoke around blast site)",
	"grenades_smoke_grenade.png^[multiply:#00ff00",
	true
)

-- Flashbang Grenade

--[[ local flash_huds = {}

grenades.register_grenade("grenades:flashbang", {
	description = "Flashbang grenade (Blinds all who look at blast)",
	image = "grenades_flashbang.png",
	clock = 4,
	on_explode = function(def, obj, pos)
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

ctf_api.register_on_match_end(function()
	for sound in pairs(sounds) do
		minetest.sound_stop(sound)
	end
	sounds = {}
end)
