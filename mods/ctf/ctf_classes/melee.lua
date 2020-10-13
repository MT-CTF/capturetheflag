minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type ~= "punch" or not reason.object or not reason.object:is_player() then
		return hp_change
	end

	local class = ctf_classes.get(reason.object)

	if class.properties.melee_bonus and reason.object:get_wielded_item():get_name():find("sword") then
		return hp_change - class.properties.melee_bonus
	end

	return hp_change
end, true)
