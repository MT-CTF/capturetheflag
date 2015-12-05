minetest.register_on_joinplayer(function(player)
	player:set_physics_override({sneak_glitch=false})
end)
