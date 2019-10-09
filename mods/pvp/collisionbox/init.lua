local collision_box = {}

minetest.register_on_dieplayer(function(player)
	local name = player:get_player_name()
	if not collision_box[name] then
		collision_box[name] = player:get_properties().collisionbox
	end
	player:set_properties({collisionbox = {0,0,0, 0,0,0}})
end)

minetest.register_on_respawnplayer(function(player)
	player:set_properties({collisionbox = collision_box[player:get_player_name()]})
end)

minetest.register_on_leaveplayer(function(player)
	collision_box[player:get_player_name()] = nil
end)
