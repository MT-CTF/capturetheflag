function preventTeamGrief(pos, oldnode, digger, dname) -- better function names, distance calculations, and message suggested by Lone_Wolf.
	minetest.set_node(pos, oldnode)
	minetest.chat_send_player(dname, "You can't mine blocks under your teammates!")
	local playerinv = digger:get_inventory()
	local stack = ItemStack(oldnode)
	playerinv:remove_item("main", stack)
end

minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger:is_player() then return end
	local dname = digger:get_player_name()
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local player_pos = player:get_pos()
		if name ~= dname then
			if ctf.players[name].team == ctf.players[dname].team then
				if math.floor(player_pos.y) == pos.y then
					if vector.distance(player_pos, pos) <= 1.5 then -- proper distance measurement uwu
						preventTeamGrief(pos, oldnode, digger, dname)
					end
				end
			end
		end
	end
end)
