dofile(minetest.get_modpath("playertag") .. "/api.lua")

ctf_flag.register_on_pick_up(function(attname, flag)
	playertag.set(minetest.get_player_by_name(attname), playertag.TYPE_BUILTIN,
			{ a=255, r=255, g=0, b=0 })
end)

ctf_flag.register_on_drop(function(attname, flag)
	playertag.set(minetest.get_player_by_name(attname), playertag.TYPE_ENTITY)
end)

ctf_flag.register_on_capture(function(attname, flag)
	playertag.set(minetest.get_player_by_name(attname), playertag.TYPE_ENTITY)
end)
