function preventTeamGrief(pos, oldnode, digger) -- better function names, distance calculations, and message suggested by Lone_Wolf.
	minetest.set_node(pos, oldnode)
	minetest.chat_send_player(digger:get_player_name(), "You can't mine blocks under your teammates!")
	local playerinv = digger:get_inventory()
	local stack = ItemStack(oldnode)
	playerinv:remove_item("main", stack)
end

minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger:is_player() then return end
	for _, player in ipairs(minetest.get_connected_players()) do
		if not player:is_player() then return end
		local name = player:get_player_name()
		local player_pos = player:get_pos()
		if name ~= digger:get_player_name() then
			if ctf.players[name].team == ctf.players[digger:get_player_name()].team then
				if math.floor(player_pos.y) == pos.y then
					if vector.distance(player_pos, pos) <= 1.5 then -- proper distance measurement uwu
						preventTeamGrief(pos, oldnode, digger)
					end
				end
			end
		end
	end
end)
