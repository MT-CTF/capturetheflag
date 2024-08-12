doors.register("ctf_teamitems:door_steel", {
	tiles = { { name = "doors_door_steel.png", backface_culling = true } },
	description = "Team Door",
	inventory_image = "doors_item_steel.png",
	groups = { node = 1, cracky = 1, level = 2 },
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	gain_open = 0.2,
	gain_close = 0.2,
})

local old_on_place = minetest.registered_craftitems["ctf_teamitems:door_steel"].on_place
minetest.override_item("ctf_teamitems:door_steel", {
	on_place = function(itemstack, placer, pointed_thing)
		local pteam = ctf_teams.get(placer)

		if pteam then
			if
				not ctf_core.pos_inside(
					pointed_thing.above,
					ctf_teams.get_team_territory(pteam)
				)
			then
				minetest.chat_send_player(
					placer:get_player_name(),
					"You can only place team doors in your own territory!"
				)
				return itemstack
			end

			local newitemstack = ItemStack("ctf_teamitems:door_steel_" .. pteam)
			newitemstack:set_count(itemstack:get_count())

			local item =
				minetest.registered_craftitems["ctf_teamitems:door_steel_" .. pteam]
			local result = item.on_place(newitemstack, placer, pointed_thing)

			if result then
				itemstack:set_count(result:get_count())
			end

			return itemstack
		end

		return old_on_place(itemstack, placer, pointed_thing)
	end,
})

local old_handle = minetest.handle_node_drops
minetest.handle_node_drops = function(pos, drops, digger)
	for i, item in ipairs(drops) do
		if item:match("ctf_teamitems:door_steel_") then
			drops[i] = "ctf_teamitems:door_steel"
		end
	end

	return old_handle(pos, drops, digger)
end

for team, def in pairs(ctf_teams.team) do
	local doorname = "ctf_teamitems:door_steel_%s"
	local modifier =
		"^[colorize:%s:190)^(ctf_teamitems_door_steel.png^[mask:ctf_teamitems_door_steel_mask.png^[colorize:%s:42)"

	doors.register(doorname:format(team), {
		tiles = {
			{
				name = "(ctf_teamitems_door_steel.png"
					.. modifier:format(def.color, def.color),
				backface_culling = true,
			},
		},
		description = "Steel Team Door",
		inventory_image = "doors_item_steel.png^[multiply:" .. def.color,
		groups = { node = 1, cracky = 1, level = 2 },
		sounds = default.node_sound_metal_defaults(),
		sound_open = "doors_steel_door_open",
		sound_close = "doors_steel_door_close",
		gain_open = 0.2,
		gain_close = 0.2,
	})
end

local old_func = default.can_interact_with_node
default.can_interact_with_node = function(player, pos)
	local pteam = ctf_teams.get(player)
	local name = minetest.get_node(pos).name

	if name:find("ctf_teamitems:") and pteam then
		if pteam == name:match("ctf_teamitems:door_steel_(.-)[_$]") then
			return true
		else
			return false
		end
	end

	return old_func(player, pos)
end
