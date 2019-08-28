-- Team interface
ctf.gui.register_tab("flags", "Flags", function(name, team)
	local result = ""
	local t = ctf.team(team)

	if not t then
		return
	end

	local x = 1
	local y = 2
	result = result .. "label[1,1;Click a flag button to go there]"

	if ctf.setting("gui.team.teleport_to_spawn") and minetest.get_setting("static_spawnpoint") then
		local x,y,z = string.match(minetest.get_setting("static_spawnpoint"), "(%d+),(%d+),(%d+)")

		result = result ..
			"button[" .. x .. "," .. y .. ";2,1;goto_"
			..f.x.."_"..f.y.."_"..f.z..";"

		result = result ..  "Spawn]"
		x = x + 2
	end

	for i=1, #t.flags do
		local f = t.flags[i]

		if x > 8 then
			x = 1
			y = y + 1
		end

		if y > 6 then
			break
		end

		result = result ..
			"button[" .. x .. "," .. y .. ";2,1;goto_"
			..f.x.."_"..f.y.."_"..f.z..";"

		if f.name then
			result = result .. f.name .. "]"
		else
			result = result .. "("..f.x..","..f.y..","..f.z..")]"
		end

		x = x + 2
	end

	minetest.show_formspec(name, "ctf:flags",
		"size[10,7]"..
		ctf.gui.get_tabs(name,team)..
		result)
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	-- Todo: fix security issue here
	-- local name = player:get_player_name()
	-- if formname == "ctf:flags" then
	-- 	for key, field in pairs(fields) do
	-- 		local x,y,z = string.match(key, "goto_([%d-]+)_([%d-]+)_([%d-]+)")
	-- 		if x and y and z then
	-- 			player:setpos({ x=tonumber(x), y=tonumber(y), z=tonumber(z) })
	-- 			return true
	-- 		end
	-- 	end
	-- end
end)

-- Flag interface
function ctf.gui.flag_board(name, pos)
	local flag = ctf_flag.get(pos)
	if not flag then
		return
	end

	local team = flag.team
	if not team then
		return
	end

	if not ctf.can_mod(name, team) then
		if ctf.player(name).team and ctf.player(name).team == team then
			ctf.gui.show(name)
		end
		return
	end

	ctf.log("gui", name .. " views flag board")

	local flag_name = flag.name

	if not ctf.setting("flag.names") then
		flag.name = nil
		return
	end

	if not ctf.setting("gui") then
		return
	end

	if not flag_name then
		flag_name = ""
	end

	if not ctf.gui.flag_data then
		ctf.gui.flag_data = {}
	end

	ctf.gui.flag_data[name] = {pos=pos}

	minetest.show_formspec(name, "ctf:flag_board",
		"size[6,3]"..
		"field[1,1;4,1;flag_name;Flag Name;"..flag_name.."]"..
		"button_exit[1,2;2,1;save;Save]"..
		"button_exit[3,2;2,1;delete;Delete]"
	)
end
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()

	if not formname=="ctf:flag_board" then
		return false
	end

	if fields.save and fields.flag_name then
		local flag = ctf_flag.get(ctf.gui.flag_data[name].pos)
		if not flag then
			return false
		end

		local team = flag.team
		if not team then
			return false
		end

		if ctf.can_mod(name,team) == false then
			return false
		end

		local flag_name = flag.name
		if not flag_name then
			flag_name = ""
		end

		flag.name = fields.flag_name

		local msg = flag_name.." was renamed to "..fields.flag_name

		if flag_name=="" then
			msg = "A flag was named "..fields.flag_name.." at ("..ctf.gui.flag_data[name].pos.x..","..ctf.gui.flag_data[name].pos.z..")"
		end

		ctf.post(team,{msg=msg,icon="flag_info"})

		return true
	elseif fields.delete then
		local pos = ctf.gui.flag_data[name].pos

		local flag = ctf_flag.get(ctf.gui.flag_data[name].pos)

		if not flag then
			return
		end

		local team = flag.team
		if not team then
			return
		end

		if ctf.can_mod(name,team) == false then
			return false
		end

		ctf_flag.delete(team,pos)

		minetest.set_node(pos,{name="air"})
		pos.y=pos.y+1
		minetest.set_node(pos,{name="air"})
		player:get_inventory():add_item("main", "ctf_flag:flag")

		return true
	end
end)
