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
		local teammates = ctf_teams.online_players[pteam].players
		-- ^ get all this player's teammates
		for i = 1, #teammates do
			minetest.chat_send_all(teammates[i])
		end

		local e
		for i = 1, #teammates do
			if teammates[i] == pname then
				e = i
			end
		end
		if e then table.remove(teammates, e) end
		minetest.chat_send_all(pname)
		minetest.chat_send_all(pteam)
		for i = 1, #teammates do
			minetest.chat_send_all(teammates[i])
		end
		if #teammates == 0 then
			minetest.chat_send_player(pname, "You are the only one in your team")
			return
		else
			local random_teammate_name = teammates[math.random(1, #teammates)]
			local random_teammate = minetest.get_player_by_name(random_teammate_name)
			local random_teammate_pos = random_teammate.get_pos()
			user:set_pos(random_teammate_pos)
			ctf_teams.chat_send_team(pteam, pname .. " teleported to " .. random_teammate_name)
			itemstack.take_craftitem(1)
			return itemstack
		end

	end,
})

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
	end,
})
