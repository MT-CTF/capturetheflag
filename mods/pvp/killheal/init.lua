local heal_val = 4 -- two hearts
minetest.register_on_dieplayer(function(player, reason)
    if reason.type == "punch" and minetest.is_player(reason.object) then
        local killer = reason.object
        if killer.get_player_name() == player.get_player_name() then return end
		killer:set_hp(math.min(killer:get_hp(killer) + heal_val, killer:get_properties().hp_max), "killheal")
	end
end)
