local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	if timer >= 6 then
		timer = 0

		for _, player in pairs(minetest.get_connected_players()) do
			local oldhp = player:get_hp()
			if oldhp > 0 then
				local newhp = oldhp + 1
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
