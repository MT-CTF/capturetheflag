local collision_box = {}

minetest.register_on_dieplayer(function(player)
	collision_box[player:get_player_name()] = player:get_properties().collisionbox
	player:set_properties({collisionbox = {0,0,0, 0,0,0}})
end)

minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()
	player:set_properties({collisionbox = collision_box[name]})
	collision_box[name] = nil
end)

minetest.register_on_leaveplayer(function(player)
	collision_box[player:get_player_name()] = nil
end)