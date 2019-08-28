ctf.gui = {
	tabs = {}
}

ctf.register_on_init(function()
	ctf._set("gui",                        true)
	ctf._set("gui.team",                   true)
	ctf._set("gui.team.initial",           "news")

	for name, tab in pairs(ctf.gui.tabs) do
		ctf._set("gui.tab." .. name,       true)
	end
end)

function ctf.gui.register_tab(name, title, func)
	ctf.gui.tabs[name] = {
		name  = name,
		title = title,
		func  = func
	}

	if ctf._defsettings and ctf._defsettings["gui.tab." .. name] == nil then
		ctf._set("gui.tab." .. name, true)
	end
end

function ctf.gui.show(name, tab, tname)
	if not tab then
		tab = ctf.setting("gui.team.initial") or "news"
	end

	if not tab or not ctf.gui.tabs[tab] or not name or name == "" then
		ctf.log("gui", "Invalid tab or name given to ctf.gui.show")
		return
	end

	if not ctf.setting("gui.team") or not ctf.setting("gui") then
		return
	end

	if not ctf.team(tname) then
		tname = ctf.player(name).team
	end

	if ctf.team(tname) then
		ctf.action("gui", name .. " views " .. tname .. "'s " .. tab .. " page")
		ctf.gui.tabs[tab].func(name, tname)
	else
		ctf.log("gui", "Invalid team given to ctf.gui.show")
	end
end

-- Get tab buttons
function ctf.gui.get_tabs(name, tname)
	local result = ""
	local id = 1
	local function addtab(name,text)
		result = result .. "button[" .. (id*2-1) .. ",0;2,1;" .. name .. ";" .. text .. "]"
		id = id + 1
	end

	for name, tab in pairs(ctf.gui.tabs) do
		if ctf.setting("gui.tab." .. name) then
			addtab(name, tab.title)
		end
	end

	return result
end

-- Team interface
ctf.gui.register_tab("news", "News", function(name, tname)
	local result = ""
	local team = ctf.team(tname).log

	if not team then
		team = {}
	end

	local amount = 0

	for i = 1, #team do
		if team[i].type == "request" then
			if ctf.can_mod(name, tname) then
				amount = amount + 2
				local height = (amount*0.5) + 0.5
				amount = amount + 1

				if team[i].mode == "diplo" then
					result = result .. "background[0.5," .. height .. ";8.3,1;diplo_" .. team[i].msg .. ".png]"
					if team[i].msg == "alliance" then
						result = result .. "label[1," .. height .. ";" ..
								team[i].team .. " offers an " ..
								minetest.formspec_escape(team[i].msg) .. " treaty]"
					else
						result = result .. "label[1," .. height .. ";" ..
								team[i].team .. " offers a " ..
								minetest.formspec_escape(team[i].msg) .. " treaty]"
					end
					result = result .. "button[6," .. height .. ";1,1;btn_y" .. i .. ";Yes]"
					result = result .. "button[7," .. height .. ";1,1;btn_n" .. i .. ";No]"
				else
					result = result .. "label[0.5," .. height .. ";RANDOM REQUEST TYPE]"
				end
			end
		else
			amount = amount + 1
			local height = (amount*0.5) + 0.5

			if height > 5 then
				break
			end

			result = result .. "label[0.5," .. height .. ";" ..
					minetest.formspec_escape(team[i].msg) .. "]"
		end
	end

	if ctf.can_mod(name, tname) then
		result = result .. "button[4,6;2,1;clear;Clear all]"
	end

	if amount == 0 then
		result = "label[0.5,1;Welcome to the news panel]" ..
			"label[0.5,1.5;News such as attacks will appear here]"
	end

	minetest.show_formspec(name, "ctf:news",
		"size[10,7]" ..
		ctf.gui.get_tabs(name, tname) ..
		result)
end)

-- Team interface
ctf.gui.register_tab("diplo", "Diplomacy", function(name, tname)
	local result = ""
	local data = {}

	local amount = 0

	for key, value in pairs(ctf.teams) do
		if key ~= tname then
			table.insert(data,{
					team  = key,
					state = ctf.diplo.get(tname, key),
					to    = ctf.diplo.check_requests(tname, key),
					from  = ctf.diplo.check_requests(key, tname)
				})
		end
	end

	result = result .. "label[1,1;Diplomacy from the perspective of " .. tname .. "]"

	for i = 1, #data do
		amount = i
		local height = (i*1)+0.5

		if height > 5 then
			break
		end

		result = result .. "background[1," .. height .. ";8.2,1;diplo_" ..
				data[i].state .. ".png]"
		result = result .. "button[1.25," .. height .. ";2,1;team_" ..
				data[i].team .. ";" .. data[i].team .. "]"
		result = result .. "label[3.75," .. height .. ";" .. data[i].state
				.. "]"

		if ctf.can_mod(name, tname) and ctf.player(name).team == tname then
			if not data[i].from and not data[i].to then
				if data[i].state == "war" then
					result = result .. "button[7.5," .. height ..
							";1.5,1;peace_" .. data[i].team .. ";Peace]"
				elseif data[i].state == "peace" then
					result = result .. "button[6," .. height ..
							";1.5,1;war_" .. data[i].team .. ";War]"
					result = result .. "button[7.5," .. height ..
							";1.5,1;alli_" .. data[i].team .. ";Alliance]"
				elseif data[i].state == "alliance" then
					result = result .. "button[6," .. height ..
							";1.5,1;peace_" .. data[i].team .. ";Peace]"
				end
			elseif data[i].from ~= nil then
				result = result .. "label[6," .. height ..
						";request recieved]"
			elseif data[i].to ~= nil then
				result = result .. "label[5.5," .. height ..
						";request sent]"
				result = result .. "button[7.5," .. height ..
						";1.5,1;cancel_" .. data[i].team .. ";Cancel]"
			end
		end
	end

	minetest.show_formspec(name, "ctf:diplo",
		"size[10,7]" ..
		ctf.gui.get_tabs(name, tname) ..
		result
	)
end)

local function formspec_is_ctf_tab(fsname)
	for name, tab in pairs(ctf.gui.tabs) do
		if fsname == "ctf:" .. name then
			return true
		end
	end
	return false
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formspec_is_ctf_tab(formname) then
		return false
	end

	local name    = player:get_player_name()
	local tplayer = ctf.player(name)
	local tname   = tplayer.team
	local team    = ctf.team(tname)

	if not team then
		return false
	end

	-- Do navigation
	for tabname, tab in pairs(ctf.gui.tabs) do
		if fields[tabname] then
			ctf.gui.show(name, tabname)
			return true
		end
	end

	-- Todo: move callbacks
	-- News page
	if fields.clear then
		team.log = {}
		ctf.needs_save = true
		ctf.gui.show(name, "news")
		return true
	end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name    = player:get_player_name()
	local tplayer = ctf.player(name)
	local tname   = tplayer.team
	local team    = ctf.team(tname)

	if not team then
		return false
	end

	if formname == "ctf:news" then
		for key, field in pairs(fields) do
			local ok, id = string.match(key, "btn_([yn])([0123456789]+)")
			if ok and id then
				if ok == "y" then
					ctf.diplo.set(tname, team.log[tonumber(id)].team, team.log[tonumber(id)].msg)

					-- Post to acceptor's log
					ctf.post(tname, {
						msg = "You have accepted the " ..
								team.log[tonumber(id)].msg .. " request from " ..
								team.log[tonumber(id)].team })

					-- Post to request's log
					ctf.post(team.log[tonumber(id)].team, {
						msg = tname .. " has accepted your " ..
								team.log[tonumber(id)].msg .. " request" })

					id = id + 1
				end

				table.remove(team.log, id)
				ctf.needs_save = true
				ctf.gui.show(name, "news")
				return true
			end
		end
	end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name    = player:get_player_name()
	local tplayer = ctf.player(name)
	local tname   = tplayer.team
	local team    = ctf.team(tname)

	if not team or formname ~= "ctf:diplo" then
		return false
	end

	for key, field in pairs(fields) do
		local tname2 = string.match(key, "team_(.+)")
		if tname2 and ctf.team(tname2) then
			ctf.gui.show(name, "diplo", tname2)
			return true
		end

		if ctf.can_mod(name, tname) then
			tname2 = string.match(key, "peace_(.+)")
			if tname2 then
				if ctf.diplo.get(tname, tname2) == "war" then
					ctf.post(tname2, {
						type = "request",
						msg  = "peace",
						team = tname,
						mode = "diplo" })
				else
					ctf.diplo.set(tname, tname2, "peace")
					ctf.post(tname, {
						msg = "You have cancelled the alliance treaty with " .. tname2 })
					ctf.post(tname2, {
						msg = tname .. " has cancelled the alliance treaty" })
				end

				ctf.gui.show(name, "diplo")
				return true
			end

			tname2 = string.match(key, "war_(.+)")
			if tname2 then
				ctf.diplo.set(tname, tname2, "war")
				ctf.post(tname, {
					msg = "You have declared war on " .. tname2 })
				ctf.post(tname2, {
					msg = tname .. " has declared war on you" })

				ctf.gui.show(name, "diplo")
				return true
			end

			tname2 = string.match(key, "alli_(.+)")
			if tname2 then
				ctf.post(tname2, {
					type = "request",
					msg  = "alliance",
					team = tname,
					mode = "diplo" })

				ctf.gui.show(name, "diplo")
				return true
			end

			tname2 = string.match(key, "cancel_(.+)")
			if tname2 then
				ctf.diplo.cancel_requests(tname, tname2)
				ctf.gui.show(name, "diplo")
				return true
			end
		end -- end if can mod
	end -- end for each field
end)
