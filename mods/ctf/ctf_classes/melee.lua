minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	if tool_capabilities.damage_groups.nopunch then return end
	if ctf_respawn_immunity.is_immune(player) then return true end

	local class = ctf_classes.get(hitter)

	if class.properties.melee_bonus and hitter:get_wielded_item():get_name():find("sword") then
		local php = player:get_hp()

		if time_from_last_punch > 1 then
			time_from_last_punch = 1
		elseif time_from_last_punch < 0.5 then
			time_from_last_punch = 0.5
		end

		if php - damage > 0 then
			minetest.after(0, function()
				player:punch(hitter, 1, {damage_groups = {fleshy = time_from_last_punch*2, nopunch = 1}}, dir)
			end)
		end
	end
end)
