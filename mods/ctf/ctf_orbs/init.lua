minetest.register_craftitem("ctf_orbs:safety_orb", {
	description = "Teleport to one of teammates randomly",
	short_description = "Orb of Safety",
	inventory_image = "orb_of_safety.png",
	stack_max = 1,
	sound = {
		use = "use.ogg"
	},
	on_use = function(itemstack, user, pointed_thing)
		if not user then
			return
		end

		if not user:is_player() then
			return
		end

		local pname = user:get_player_name()
		local pteam = ctf_teams.get(pname)
		local teammates_count = ctf_teams.online_players[pteam].count
		if teammates_count == 1 then
			minetest.chat_send_player(pname, "You are the only one in your team")
			return
		end
		local teammates = {}
		for player, _ in pairs(ctf_teams.online_players[pteam].players) do
			if pname ~= player then
				table.insert(teammates, player)
			end
		end
		local random_teammate_name = teammates[math.random(1, #teammates)]
		local random_teammate = minetest.get_player_by_name(random_teammate_name)
		local random_teammate_pos = random_teammate:get_pos()
		user:set_pos(random_teammate_pos)
		ctf_teams.chat_send_team(pteam, pname .. " teleported to " .. random_teammate_name)
		itemstack:take_item()
		return itemstack
	end,
})
--[[
minetest.register_craftitem("ctf_orbs:protection_orb", {
	description = "Teleport to the teammate carrying enemy flag(if any)",
	short_description = "Orb of Protection",
	inventory_image = "orb_of_protection.png",
	stack_max = 1,
	sound = {
		use = "use.ogg"
	},
	on_use = function(itemstack, user, pointed_thing)
		if not user then
			return
		end

		if not user:is_player() then
			return
		end

		local pname = user:get_player_name()
		local pteam = ctf_teams.get(pname)
		local teammates_count = ctf_teams.online_players[pteam].count
		if teammates_count == 1 then
			minetest.chat_send_player(pname, "You are the only one in your team")
			return
		end
		if not ctf_modebase.team_flag_takers[pteam] then
			minetest.chat_send_player(pname, "No one carring flag")
			return
		end
		local teammate_flag_carriers = {}
		local i = 1
		for flag_carrier, _ in pairs(ctf_modebase.team_flag_takers[pteam]) do
			if flag_carrier ~= pname then
				teammate_flag_carriers[i] = flag_carrier
			end
		end
		local random_flag_carrier_name = teammate_flag_carriers[math.random(1, #teammate_flag_carriers)]
		local random_flag_carrier = minetest.get_player_by_name(random_flag_carrier_name)
		local random_flag_carrier_pos = random_teammate:get_pos()
		user:set_pos(random_flag_carrier_pos)
		ctf_teams.chat_send_team(pteam, pname .. " teleported to " .. random_flag_carrier_name)
		itemstack:take_item()
		return itemstack
	end,
})
--]]
