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

grenades.register_grenade("ctf_mode_nade_fight:black_hole_grenade", {
	description = "Black Hole Grenade, sucks players in and holds them for a few seconds",
	image = "ctf_mode_nade_fight_black_hole_grenade.png",
	clock = 3,
	radius = 3,
	on_collide = function()
		return true
	end,
	on_explode = function(def, pos, name)
		local black_hole = minetest.add_entity(pos, "ctf_mode_nade_fight:black_hole")

		minetest.add_particlespawner({
			amount = 50,
			time = 0.3,
			minpos = vector.subtract(pos, def.radius),
			maxpos = vector.add(pos, def.radius),
			minvel = {x = 0, y = 0, z = 0},
			maxvel = {x = 0, y = 0, z = 0},
			minacc = {x = 0, y = 0, z = 0},
			maxacc = {x = 0, y = 0, z = 0},
			minexptime = 2,
			maxexptime = 2.5,
			minsize = 1,
			maxsize = 1.5,
			collisiondetection = true,
			collision_removal = false,
			vertical = false,
			texture = "default_obsidian_block.png",
		})

		minetest.sound_play("grenades_glasslike_break", {
			pos = pos,
			gain = 1.4,
			pitch = 0.6,
			max_hear_distance = 32,
		})

		local hiss = minetest.sound_play("grenades_hiss", {
			pos = pos,
			gain = 1.5,
			pitch = 0.2,
			loop = true,
			max_hear_distance = def.radius * 2,
		})

		minetest.after(2, function()
			black_hole:remove()
			minetest.sound_stop(hiss)
		end)

		for _, v in pairs(minetest.get_objects_inside_radius(pos, def.radius)) do
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
					v:add_velocity(vector.multiply(vector.direction(footpos, pos), vector.distance(footpos, pos) * 8))
					minetest.after(0.2, function() v:set_attach(black_hole) end)
				end
			end
		end
	end,
})

minetest.register_entity("ctf_mode_nade_fight:black_hole", {
	is_visible = true,
	visual = "wielditem",
	wield_item = "default:obsidian_glass",
	visual_size = vector.new(0.5, 0.5, 0.5),
	physical = false,
	makes_footstep_sound = false,
	backface_culling = false,
	static_save = false,
	pointable = false,
	on_punch = function() return true end,
})

local knockback_amount = 32
grenades.register_grenade("ctf_mode_nade_fight:knockback_grenade", {
	description = "Knockback Grenade, Blasts players far away",
	image = "ctf_mode_nade_fight_knockback_grenade.png",
	clock = 3,
	radius = 3,
	on_collide = function()
		return true
	end,
	on_explode = function(def, pos, name)
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
			pitch = 1.4,
			max_hear_distance = 32,
		})

		for _, v in pairs(minetest.get_objects_inside_radius(pos, def.radius)) do
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
					v:add_velocity(vector.multiply(vector.direction(pos, headpos), knockback_amount))
				end
			end
		end
	end,
})

local WEAR_MAX = 65535
local grenade_list = {
	{name = "grenades:frag_small"                   , cooldown = 2.5},
	{name = "ctf_mode_nade_fight:black_hole_grenade", cooldown = 6  },
	{name = "ctf_mode_nade_fight:knockback_grenade" , cooldown = 4  },
}

local function swap_next_grenade(itemstack, user, pointed)
	if itemstack:get_wear() > 1 then return end

	local nadeid = itemstack:get_name():sub(-1, -1)
	local nadeid_next = nadeid + 1

	if nadeid_next > #grenade_list then
		nadeid_next = 1
	end

	return "ctf_mode_nade_fight:grenade_tool_"..nadeid_next
end

for idx, info in ipairs(grenade_list) do
	local def = minetest.registered_items[info.name]

	minetest.register_tool("ctf_mode_nade_fight:grenade_tool_"..idx, {
		description = def.description..minetest.colorize("gold", "\nRightclick off cooldown to switch to other grenades"),
		inventory_image = def.inventory_image,
		wield_image = def.inventory_image,
		inventory_overlay = "ctf_modebase_special_item.png",
		on_use = function(itemstack, user, pointed_thing)
			if itemstack:get_wear() > 1 then return end

			if itemstack:get_wear() <= 1 then
				grenades.throw_grenade(info.name, 17, user)
			end

			itemstack:set_wear(WEAR_MAX - 6000)
			ctf_modebase.update_wear.start_update(
				user:get_player_name(),
				"ctf_mode_nade_fight:grenade_tool_"..idx,
				WEAR_MAX/info.cooldown,
				true
			)

			return itemstack
		end,
		on_place = function(itemstack, user, pointed, ...)
			local node = false
			local pointed_def

			if pointed and pointed.under then
				node = minetest.get_node(pointed.under)
				pointed_def = minetest.registered_nodes[node.name]
			end

			if node and pointed_def.on_rightclick then
				return pointed_def.on_rightclick(pointed.under, node, user, itemstack, pointed)
			else
				return swap_next_grenade(itemstack, user, pointed)
			end
		end,
		on_secondary_use = swap_next_grenade
	})
end