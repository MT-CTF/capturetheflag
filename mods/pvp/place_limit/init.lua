local last_placement = {}

minetest.register_on_joinplayer(function(player)
	-- player has to wait after join before they can place a node
	last_placement[player:get_player_name()] = minetest.get_us_time()
end)

minetest.register_on_leaveplayer(function(player)
	last_placement[player:get_player_name()] = nil
end)

minetest.register_on_placenode(function(pos, _newnode, placer, oldnode, _itemstack, _pointed_thing)
	local name = placer:get_player_name()
	local time = minetest.get_us_time()
	if (time - last_placement[name]) / 1e6 < 0.2 then
		minetest.set_node(pos, oldnode)
		return true
	end
	last_placement[name] = time
end)
