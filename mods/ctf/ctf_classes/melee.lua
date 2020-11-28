minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type ~= "punch" or not reason.object or not reason.object:is_player() then
		return hp_change
	end

	local class = ctf_classes.get(reason.object)

	if class.properties.melee_bonus and reason.object:get_wielded_item():get_name():find("sword") then
		local change = hp_change - class.properties.melee_bonus

		if player:get_hp() + change <= 0 and player:get_hp() + hp_change > 0 then
			local wielded_item = reason.object:get_wielded_item()

			for i = 1, #ctf.registered_on_killedplayer do
				ctf.registered_on_killedplayer[i](
					player:get_player_name(),
					reason.object:get_player_name(),
					wielded_item,
					wielded_item:get_tool_capabilities()
				)
			end
		end

		return change
	end

	return hp_change
end, true)
