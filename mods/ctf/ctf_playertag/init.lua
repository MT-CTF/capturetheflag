dofile(minetest.get_modpath("ctf_playertag") .. "/api.lua")

ctf_flag.register_on_pick_up(function(attname, flag)
	local tcolor = ctf_colors.get_color(ctf.player(attname))
	ctf_playertag.set(minetest.get_player_by_name(attname),
			ctf_playertag.TYPE_BUILTIN, tcolor.css)
end)

ctf_flag.register_on_drop(function(attname, flag)
	ctf_playertag.set(minetest.get_player_by_name(attname),
			ctf_playertag.TYPE_ENTITY)
end)

ctf_flag.register_on_capture(function(attname, flag)
	ctf_playertag.set(minetest.get_player_by_name(attname),
			ctf_playertag.TYPE_ENTITY)
end)

ctf_match.register_on_new_match(function()
	for name, settings in pairs(ctf_playertag.get_all()) do
		if settings.type == ctf_playertag.TYPE_BUILTIN then
			ctf_playertag.set(minetest.get_player_by_name(name),
					ctf_playertag.TYPE_ENTITY)
		end
	end
end)
