local settings = minetest.settings

local regular = settings:get_bool("grenades.enable_regular")
local flash = settings:get_bool("grenades.enable_flashbang")
local smoke = settings:get_bool("grenades.enable_smoke")


-- Regular Grenade

if regular ~= false then
	grenades.register_grenade("regular", {
		description = "Regular grenade (Kills anyone near blast)",
		image = "grenades_regular.png",
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
				minvel = {x=0, y=5, z=0},
				maxvel = {x=0, y=7, z=0},
				minacc = {x=0, y=1, z=0},
				maxacc = {x=0, y=1, z=0},
				minexptime = 0.3,
				maxexptime = 0.6,
				minsize = 7,
				maxsize = 10,
				collisiondetection = true,
				collision_removal = false,
				vertical = false,
				texture = "grenades_smoke.png",
			})

			for k, v in ipairs(minetest.get_objects_inside_radius(pos, radius)) do
				if v:is_player() and v:get_hp() > 0 then
					v:punch(player, 2, {damage_groups = {fleshy = 21.5-vector.distance(pos, v:get_pos())}}, nil)
				end
			end
		end,
	})
end

-- Flashbang Grenade

if flash ~= false then
	grenades.register_grenade("flashbang", {
		description = "Flashbang grenade (Blinds all who look at blast)",
		image = "grenades_flashbang.png",
		on_explode = function(pos, name)
			for k, v in ipairs(minetest.get_objects_inside_radius(pos, 20)) do
				if v:is_player() and v:get_hp() > 0 then
					local playerdir = vector.round(v:get_look_dir())
					local grenadedir = vector.round(vector.direction(v:get_pos(), pos))
					local pname = v:get_player_name()

					if vector.equals(playerdir, grenadedir) then
						for i = 0, 3, 1 do
							local key = v:hud_add({
								hud_elem_type = "image",
								position = {x = 0, y = 0},
								name = "flashbang hud "..pname,
								scale = {x = -200, y = -200},
								text = "grenades_white.png^[opacity:"..tostring(255-(i*17)),
								alignment = {x = 0, y = 0},
								offset = {x = 0, y = 0}
							})

							minetest.after(1.6 * i, function()
								if minetest.get_player_by_name(pname) then
									minetest.get_player_by_name(pname):hud_remove(key)
								end
							end)
						end
					end

				end
			end
		end,
	})
end

-- Smoke Grenade

if smoke ~= false then
	grenades.register_grenade("smoke", {
		description = "Smoke grenade (Generates smoke around blast site)",
		image = "grenades_smoke_grenade.png",
		on_explode = function(pos, name)
			for i = 0, 5, 1 do
				minetest.add_particlespawner({
					amount = 20,
					time = 11,
					minpos = vector.subtract(pos, 3.5),
					maxpos = vector.add(pos, 3.5),
					minvel = {x=0, y=2, z=0},
					maxvel = {x=0, y=3, z=0},
					minacc = {x=1, y=0.2, z=1},
					maxacc = {x=1, y=0.2, z=1},
					minexptime = 0.3,
					maxexptime = 1,
					minsize = 150,
					maxsize = 150,
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
			interval = 5,
		}
	})
end

--
-- Crafts
--

if settings:get_bool("grenades.enable_crafting") == true then

	-- Regular Grenade

	if regular ~= false then
		minetest.register_craft({
			type = "shaped",
			output = "grenades:grenade_regular",
			recipe = {
				{"", "default:steel_ingot", ""},
				{"default:steel_ingot", "default:coal_lump", "default:steel_ingot"},
				{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
			},
		})
	end

	-- Smoke Grenade

	if smoke ~= false then
		minetest.register_craft({
			type = "shaped",
			output = "grenades:grenade_smoke",
			recipe = {
				{"", "default:steel_ingot", ""},
				{"default:steel_ingot", "grenades:gun_powder", "default:steel_ingot"},
				{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
			}
		})
	end

	--Flashbang Grenade

	if flash ~= false then
		minetest.register_craft({
			type = "shaped",
			output = "grenades:grenade_flashbang",
			recipe = {
				{"", "default:steel_ingot", ""},
				{"default:steel_ingot", "default:torch", "default:steel_ingot"},
				{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
			},
		})
	end

	-- Other

	minetest.register_craftitem("grenades:gun_powder", {
		description = "A dark powder used for crafting some grenades",
		inventory_image = "grenades_gun_powder.png"
	})

	minetest.register_craft({
		type = "shapeless",
		output = "grenades:gun_powder",
		recipe = {"default:coal_lump 4"},
	})
end
