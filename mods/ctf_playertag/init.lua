dofile(minetest.get_modpath("ctf_playertag") .. "/api.lua")

ctf_flag.register_on_pick_up(function(attname, flag)
	local _, color = ctf_colors.get_color(ctf.player(attname))
	color = color:gsub("0x", "#")
	playertag.set(minetest.get_player_by_name(attname), playertag.TYPE_BUILTIN,
					color)
end)

ctf_flag.register_on_drop(function(attname, flag)
	playertag.set(minetest.get_player_by_name(attname), playertag.TYPE_ENTITY)
end)

ctf_flag.register_on_capture(function(attname, flag)
	playertag.set(minetest.get_player_by_name(attname), playertag.TYPE_ENTITY)
end)

ctf_match.register_on_new_match(function()
	for name, settings in pairs(playertag.get_all()) do
		if settings.type == playertag.TYPE_BUILTIN then
			playertag.set(minetest.get_player_by_name(name), playertag.TYPE_ENTITY)
		end
	end
end)
