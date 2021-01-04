-- Code by Apelta. Mutelated by Lone_Wolf. Mutelated again by Apelta.

function isSabotage(pos, oldnode, digger) -- used for paxel, hence why it is now a separate function
	local dname = digger:get_player_name()
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()

		if name ~= dname and ctf.players[name].team == ctf.players[dname].team then
			local player_pos = player:get_pos()

			if math.floor(player_pos.y) == pos.y and vector.distance(player_pos, pos) <= 1.5 then
				minetest.set_node(pos, oldnode)
				for _, item in pairs(minetest.get_node_drops(oldnode)) do -- Properly remove items dropped by nodes, now also protects against possible crash by nodes dropping more than one item.
					digger:get_inventory():remove_item("main", ItemStack(item))
				end
				minetest.chat_send_player(dname, "You can't mine blocks under your teammates!")
				return true
			end
		end
	end
end


minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger:is_player() then return end
	isSabotage(pos, oldnode, digger)
end)
