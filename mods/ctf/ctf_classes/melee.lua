local sword_special_timer = {}
local SWORD_SPECIAL_COOLDOWN = 20
local function sword_special_timer_func(pname, timeleft)
	sword_special_timer[pname] = timeleft

	if timeleft - 2 >= 0 then
		minetest.after(2, sword_special_timer_func, pname, timeleft - 2)
	else
		sword_special_timer[pname] = nil
	end
end

minetest.register_tool("ctf_classes:sword_bronze", {
	description = "Knight's Sword\nSneak+Rightclick items/air to place marker\nRightclick enemies to place marker listing all enemies in area",
	inventory_image = "default_tool_bronzesword.png",
	tool_capabilities = {
		full_punch_interval = 0.8,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=2.5, [2]=1.20, [3]=0.35}, uses=0, maxlevel=2},
		},
		damage_groups = {fleshy=6, sword=1},
		punch_attack_uses = 0,
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = function(itemstack, placer, pointed_thing)
		local pname = placer:get_player_name()
		if not pointed_thing then return end

		if sword_special_timer[pname] and placer:get_player_control().sneak then
			minetest.chat_send_player(pname, "You have to wait "..sword_special_timer[pname].."s to place marker again")

			if pointed_thing.type == "node" then
				return minetest.item_place(itemstack, placer, pointed_thing)
			else
				return
			end
		end

		local pteam = ctf.player(pname).team
		if not pteam then -- can be nil during map change
			return
		end

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
				ctf_marker.add_marker(pname, pteam, pos, (" found enemies: <%s>]"):format(table.concat(enemies, ", ")))
			end

			return
		end

		if pointed_thing.type == "node" then
			return minetest.item_place(itemstack, placer, pointed_thing)
		end

		-- Check if player is sneaking before placing marker
		if not placer:get_player_control().sneak then return end

		sword_special_timer[pname] = 4
		sword_special_timer_func(pname, 4)

		minetest.registered_chatcommands["m"].func(pname, "placed with sword")
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if pointed_thing then
			minetest.registered_tools["ctf_classes:sword_bronze"].on_place(itemstack, user, pointed_thing)
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
