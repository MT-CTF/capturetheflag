-- Capture The Flag mod: anticoward
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type == "fall" and player:get_hp() + hp_change <= 0 then
		return (-player:get_hp()) + 1
	end

	return hp_change
end, true)
