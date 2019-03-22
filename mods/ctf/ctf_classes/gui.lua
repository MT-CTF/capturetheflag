function ctf_classes.show_gui(name, player)
	player = player or minetest.get_player_by_name(name)
	assert(player.get_player_name)
	if not ctf_classes.can_change(player) then
		minetest.chat_send_player(name, "Move closer to the flag to change classes!")
		return
	end

	local fs = {
		"size[9,3.2]"
	}


	local x = 0
	local y = 0
	for _, class in pairs(ctf_classes.__classes_ordered) do
		fs[#fs + 1] = "container["
		fs[#fs + 1] = tostring(x*3)
		fs[#fs + 1] = ","
		fs[#fs + 1] = tostring(y*3.5)
		fs[#fs + 1] = "]"
		fs[#fs + 1] = "image[1,-0.1;1,1;ctf_classes_"
		fs[#fs + 1] = class.name
		fs[#fs + 1] = ".png]"
		fs[#fs + 1] = "style[select_"
		fs[#fs + 1] = class.name
		fs[#fs + 1] = ";bgcolor="
		fs[#fs + 1] = class.color
		fs[#fs + 1] = "]"
		fs[#fs + 1] = "tableoptions[background=#00000000;highlight=#00000000;border=false]"
		fs[#fs + 1] = "tablecolumns[color;text]"
		fs[#fs + 1] = "table[0,0.9;2.8,1.7;;"
		fs[#fs + 1] = class.color
		fs[#fs + 1] = ","
		fs[#fs + 1] = minetest.formspec_escape(class.description)
		fs[#fs + 1] = ",,"
		for _, item in pairs(class.pros) do
			fs[#fs + 1] = ",#cfc," .. minetest.formspec_escape(item)
		end
		for _, item in pairs(class.cons) do
			fs[#fs + 1] = ",#fcc," .. minetest.formspec_escape(item)
		end
		fs[#fs + 1] = "]"
		fs[#fs + 1] = "button_exit[0.5,2.7;2,1;select_"
		fs[#fs + 1] = class.name
		fs[#fs + 1] = ";Select]"
		fs[#fs + 1] = "container_end[]"

		x = x + 1
		if x > 3 then
			x = 0
			y = y + 1
		end
	end

	minetest.show_formspec(name, "ctf_classes:select", table.concat(fs))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "ctf_classes:select" then
		return false
	end

	if not ctf_classes.can_change(player) then
		minetest.chat_send_player(player:get_player_name(),
				"Move closer to the flag to change classes!")
	end

	for name in pairs(ctf_classes.__classes) do
		if fields["select_" .. name] then
			ctf_classes.set(player, name)
			return true
		end
	end
end)
