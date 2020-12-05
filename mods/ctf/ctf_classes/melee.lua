minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type ~= "punch" or not reason.object or not reason.object:is_player() then
		return hp_change
	end

	local class = ctf_classes.get(reason.object)

	if class.properties.melee_bonus and reason.object:get_wielded_item():get_name():find("sword") then
		local change = hp_change - class.properties.melee_bonus

		if player:get_hp() + change <= 0 and player:get_hp() + hp_change > 0 then
			local wielded_item = reason.object:get_wielded_item()

			for i = 1, #ctf.registered_on_killedplayer do
				ctf.registered_on_killedplayer[i](
					player:get_player_name(),
					reason.object:get_player_name(),
					wielded_item,
					wielded_item:get_tool_capabilities()
				)
			end
		end

		return change
	end

	return hp_change
end, true)


local sword_special_timer = {}
local SWORD_SPECIAL_COOLDOWN = 40
local function sword_special_timer_func(pname, timeleft)
	sword_special_timer[pname] = timeleft

	if timeleft - 10 >= 0 then
		minetest.after(10, sword_special_timer_func, pname, timeleft - 10)
	else
		sword_special_timer[pname] = nil
	end
end

minetest.register_tool("ctf_classes:sword_steel", {
	description = "Knight's Sword\nRightclick enemies/items/air to place marker\nMark enemies to show all enemies in area",
	inventory_image = "default_tool_steelsword.png",
	tool_capabilities = {
		full_punch_interval = 0.8,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=2.5, [2]=1.20, [3]=0.35}, uses=0, maxlevel=2},
		},
		damage_groups = {fleshy=6},
		punch_attack_uses = 0,
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = function(itemstack, placer, pointed_thing)
		local pname = placer:get_player_name()
		if not pointed_thing then return end

		if sword_special_timer[pname] then
			minetest.chat_send_player(pname, "You can't place a marker yet (>"..sword_special_timer[pname].."s left)")

			if pointed_thing.type == "node" then
				return minetest.item_place(itemstack, placer, pointed_thing)
			else
				return
			end
		end

		local pteam = ctf.player(pname).team

		if pointed_thing.type == "object" and pointed_thing.ref:is_player() then
			if ctf_match.is_in_build_time() then return end

			local enemies = {}
			local pos = pointed_thing.ref:get_pos()

			sword_special_timer[pname] = SWORD_SPECIAL_COOLDOWN
			sword_special_timer_func(pname, SWORD_SPECIAL_COOLDOWN)

			for _, p in pairs(minetest.get_connected_players()) do
				local name = p:get_player_name()

				if pteam ~= ctf.player(name).team and
				vector.distance(p:get_pos(), pos) <= 10 then
					table.insert(enemies, name)
				end
			end

			if #enemies > 0 then
				ctf_marker.remove_marker(pteam)
				ctf_marker.add_marker(pname, pteam, pos, ("[Enemies Found!: <%s>]"):format(table.concat(enemies, ", ")))
			end

			return
		end

		if pointed_thing.type == "node" then
			return minetest.item_place(itemstack, placer, pointed_thing)
		end

		sword_special_timer[pname] = 20
		sword_special_timer_func(pname, 20)

		minetest.registered_chatcommands["m"].func(pname, "Marked with "..pname.."'s sword")
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if pointed_thing then
			minetest.registered_tools["ctf_classes:sword_steel"].on_place(itemstack, user, pointed_thing)
		end
	end,
})

minetest.register_on_leaveplayer(function(player)
	sword_special_timer[player:get_player_name()] = nil
end)

ctf_match.register_on_new_match(function()
	sword_special_timer = {}
end)

ctf.register_on_new_game(function()
	sword_special_timer = {}
end)
