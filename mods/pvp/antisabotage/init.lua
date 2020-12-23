function myFunc(pos, oldnode, player, digger)
	minetest.set_node(pos, oldnode)
	minetest.chat_send_player(digger:get_player_name(), "You may not mine blocks under where your teammates are near!")
	local playerinv = player:get_inventory()
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
					if math.floor(player_pos.x+1) >= pos.x and pos.x >= math.floor(player_pos.x-.5) and math.floor(player_pos.z+1.5) >= pos.z and pos.z >= math.floor(player_pos.z-.5) then
						myFunc(pos, oldnode, player, digger)
					end
				end
			end
		end
	end
end)