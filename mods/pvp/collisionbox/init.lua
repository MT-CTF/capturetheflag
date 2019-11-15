local collision_box = {}

minetest.register_on_dieplayer(function(player)
	local name = player:get_player_name()
	collision_box[name] = player:get_properties().collisionbox
	player:set_properties({ collisionbox = { 0,0,0, 0,0,0 } })
end)

minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()
	player:set_properties({ collisionbox = collision_box[name] })
	collision_box[name] = nil
end)

ctf_match.register_on_new_match(function()
	-- Loop through all dead players and manually reset
	-- collision box, because on_respawnplayer isn't called
	-- when the player is respawned at the start of a new match
	for name, box in pairs(collision_box) do
		local player = minetest.get_player_by_name(name)
		if player then
			player:set_properties({ collisionbox = box })
		end
		collision_box[name] = nil
	end
end)

minetest.register_on_leaveplayer(function(player)
	collision_box[player:get_player_name()] = nil
end)
