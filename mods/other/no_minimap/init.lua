minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({
		minimap = false,
	})
end)
