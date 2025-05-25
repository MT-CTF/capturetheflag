local timer = 0
core.register_globalstep(function(dtime)
	if not ctf_modebase.current_mode then return end

	local health_per_sec = ctf_modebase:get_current_mode().hp_regen or 0.3
	if health_per_sec <= 0 then return end

	timer = timer + dtime

	if timer >= 2/health_per_sec then
		timer = 0

		for _, player in pairs(core.get_connected_players()) do
			local oldhp = player:get_hp()
			if not ctf_combat_mode.in_combat(player) and oldhp > 0 then
				local newhp = oldhp + 2
				if newhp > player:get_properties().hp_max then
					newhp = player:get_properties().hp_max
				end
				if oldhp ~= newhp then
					player:set_hp(newhp)
				end
			end
		end
	end
end)
